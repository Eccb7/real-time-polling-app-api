class Api::V1::PollsController < ApplicationController
  before_action :set_poll, only: [ :show, :update, :destroy ]

  def index
    polls = Poll.includes(:user, :options, :votes)
               .active
               .not_expired
               .order(created_at: :desc)

    render json: {
      polls: polls.map { |poll| poll_response(poll) }
    }
  end

  def show
    render json: { poll: poll_response(@poll) }
  end

  def create
    poll = current_user.polls.build(poll_params)

    if poll.save
      # Create options if provided
      if params[:options].present?
        options_data = params[:options].map do |option_text|
          { text: option_text, poll: poll }
        end

        poll.options.create!(options_data)
      end

      # Broadcast poll creation
      ActionCable.server.broadcast(
        "polls_channel",
        {
          type: "poll_created",
          poll: poll_response(poll.reload)
        }
      )

      render json: {
        message: "Poll created successfully",
        poll: poll_response(poll)
      }, status: :created
    else
      render json: { errors: poll.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    return render json: { error: "Unauthorized" }, status: :forbidden unless @poll.user == current_user

    if @poll.update(poll_params)
      # Broadcast poll update
      ActionCable.server.broadcast(
        "polls_channel",
        {
          type: "poll_updated",
          poll: poll_response(@poll)
        }
      )

      render json: {
        message: "Poll updated successfully",
        poll: poll_response(@poll)
      }
    else
      render json: { errors: @poll.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    return render json: { error: "Unauthorized" }, status: :forbidden unless @poll.user == current_user

    @poll.destroy

    # Broadcast poll deletion
    ActionCable.server.broadcast(
      "polls_channel",
      {
        type: "poll_deleted",
        poll_id: @poll.id
      }
    )

    render json: { message: "Poll deleted successfully" }
  end

  def my_polls
    polls = current_user.polls.includes(:options, :votes).order(created_at: :desc)
    render json: {
      polls: polls.map { |poll| poll_response(poll) }
    }
  end

  private

  def set_poll
    @poll = Poll.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Poll not found" }, status: :not_found
  end

  def poll_params
    params.require(:poll).permit(:title, :description, :expires_at, :active)
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
end
