class Api::V1::PollsController < ApplicationController
  include RateLimitable

  before_action :set_poll, only: [ :show, :update, :destroy ]
  before_action :check_poll_ownership, only: [ :update, :destroy ]

  # GET /api/v1/polls
  # Returns paginated list of active, non-expired polls
  # Query params:
  #   - page: page number (default: 1)
  #   - per_page: items per page (default: 10, max: 50)
  #   - sort: 'recent', 'popular', 'ending_soon' (default: 'recent')
  def index
    @polls = Poll.includes(:user, :options, :votes)
                 .active
                 .not_expired

    # Apply sorting
    @polls = case params[:sort]
    when "popular"
               @polls.popular
    when "ending_soon"
               @polls.order(:expires_at)
    else
               @polls.recent
    end

    # Pagination
    page = [ params[:page].to_i, 1 ].max
    per_page = [ [ params[:per_page].to_i, 1 ].max, 50 ].min
    per_page = 10 if per_page == 1

    @polls = @polls.page(page).per(per_page)

    render json: {
      polls: @polls.map { |poll| poll_response(poll) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_pages: @polls.total_pages,
        total_count: @polls.total_count
      }
    }
  end

  # GET /api/v1/polls/:id
  # Returns detailed information about a specific poll
  def show
    @poll.increment_view_count!
    render json: { poll: poll_response(@poll) }
  end

  # POST /api/v1/polls
  # Creates a new poll with options
  # Body: { poll: {...}, options: [...] }
  def create
    @poll = current_user.polls.build(poll_params)

    ActiveRecord::Base.transaction do
      if @poll.save
        create_poll_options if params[:options].present?

        broadcast_poll_event("poll_created", @poll)

        render json: {
          message: "Poll created successfully",
          poll: poll_response(@poll)
        }, status: :created
      else
        render json: { errors: @poll.errors.full_messages }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # PUT/PATCH /api/v1/polls/:id
  # Updates an existing poll (owner only)
  def update
    if @poll.update(poll_params)
      broadcast_poll_event("poll_updated", @poll)

      render json: {
        message: "Poll updated successfully",
        poll: poll_response(@poll)
      }
    else
      render json: { errors: @poll.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/polls/:id
  # Deletes a poll (owner only)
  def destroy
    poll_id = @poll.id
    @poll.destroy

    broadcast_poll_deletion(poll_id)

    render json: { message: "Poll deleted successfully" }
  end

  # GET /api/v1/polls/my_polls
  # Returns current user's polls
  def my_polls
    @polls = current_user.polls
                        .includes(:options, :votes)
                        .order(created_at: :desc)

    render json: {
      polls: @polls.map { |poll| poll_response(poll) }
    }
  end

  # GET /api/v1/polls/:id/analytics
  # Returns detailed analytics for a poll (owner only)
  def analytics
    return render json: { error: "Unauthorized" }, status: :forbidden unless @poll.user == current_user

    analytics_data = {
      total_votes: @poll.total_votes,
      view_count: @poll.view_count,
      completion_rate: calculate_completion_rate(@poll),
      votes_over_time: votes_over_time_data(@poll),
      geographic_distribution: geographic_vote_distribution(@poll),
      option_performance: @poll.results
    }

    render json: { analytics: analytics_data }
  end

  private

  def set_poll
    @poll = Poll.includes(:user, :options, :votes).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Poll not found" }, status: :not_found
  end

  def check_poll_ownership
    unless @poll.user == current_user
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end

  def poll_params
    params.require(:poll).permit(:title, :description, :expires_at, :active)
  end

  def create_poll_options
    options_data = params[:options].map do |option_text|
      { text: option_text.strip, poll: @poll }
    end.reject { |option| option[:text].blank? }

    raise ActiveRecord::RecordInvalid.new(@poll) if options_data.length < 2

    @poll.options.create!(options_data)
  end

  def poll_response(poll)
    {
      id: poll.id,
      title: poll.title,
      description: poll.description,
      active: poll.active,
      expires_at: poll.expires_at,
      expired: poll.expired?,
      total_votes: poll.total_votes,
      view_count: poll.view_count,
      created_at: poll.created_at,
      updated_at: poll.updated_at,
      user: {
        id: poll.user.id,
        name: poll.user.name
      },
      options: poll.options.map do |option|
        {
          id: option.id,
          text: option.text,
          votes_count: option.votes_count,
          percentage: option.vote_percentage
        }
      end,
      results: poll.results
    }
  end

  def broadcast_poll_event(event_type, poll)
    ActionCable.server.broadcast(
      "polls_channel",
      {
        type: event_type,
        poll: poll_response(poll),
        timestamp: Time.current.iso8601
      }
    )
  end

  def broadcast_poll_deletion(poll_id)
    ActionCable.server.broadcast(
      "polls_channel",
      {
        type: "poll_deleted",
        poll_id: poll_id,
        timestamp: Time.current.iso8601
      }
    )
  end

  def calculate_completion_rate(poll)
    return 0 if poll.view_count == 0
    (poll.total_votes.to_f / poll.view_count * 100).round(2)
  end

  def votes_over_time_data(poll)
    poll.votes
        .group_by_hour(:created_at, last: 24)
        .count
        .transform_keys { |k| k.strftime("%Y-%m-%d %H:00") }
  end

  def geographic_vote_distribution(poll)
    # This would require storing user location data
    # For now, return empty hash
    {}
  end
end
