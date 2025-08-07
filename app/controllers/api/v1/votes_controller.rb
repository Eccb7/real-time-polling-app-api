class Api::V1::VotesController < ApplicationController
  before_action :set_poll, only: [ :create ]
  before_action :set_option, only: [ :create ]

  def create
    # Check if user already voted on this poll
    existing_vote = current_user.votes.find_by(poll: @poll)

    if existing_vote
      return render json: { error: "You have already voted on this poll" }, status: :unprocessable_entity
    end

    # Check if poll is active and not expired
    if !@poll.active? || @poll.expired?
      return render json: { error: "Poll is not active or has expired" }, status: :unprocessable_entity
    end

    vote = current_user.votes.build(
      poll: @poll,
      option: @option
    )

    if vote.save
      # Broadcast vote update
      ActionCable.server.broadcast(
        "poll_#{@poll.id}",
        {
          type: "vote_cast",
          poll: poll_response(@poll.reload),
          voter: {
            id: current_user.id,
            name: current_user.name
          }
        }
      )

      # Also broadcast to general polls channel
      ActionCable.server.broadcast(
        "polls_channel",
        {
          type: "poll_updated",
          poll: poll_response(@poll)
        }
      )

      render json: {
        message: "Vote cast successfully",
        vote: vote_response(vote),
        poll: poll_response(@poll)
      }, status: :created
    else
      render json: { errors: vote.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    vote = current_user.votes.find(params[:id])
    poll = vote.poll

    # Only allow vote deletion if poll is still active
    if !poll.active? || poll.expired?
      return render json: { error: "Cannot change vote on inactive or expired poll" }, status: :unprocessable_entity
    end

    vote.destroy

    # Broadcast vote update
    ActionCable.server.broadcast(
      "poll_#{poll.id}",
      {
        type: "vote_removed",
        poll: poll_response(poll.reload),
        voter: {
          id: current_user.id,
          name: current_user.name
        }
      }
    )

    # Also broadcast to general polls channel
    ActionCable.server.broadcast(
      "polls_channel",
      {
        type: "poll_updated",
        poll: poll_response(poll)
      }
    )

    render json: { message: "Vote removed successfully" }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Vote not found" }, status: :not_found
  end

  private

  def set_poll
    @poll = Poll.find(params[:poll_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Poll not found" }, status: :not_found
  end

  def set_option
    @option = @poll.options.find(params[:vote][:option_id] || params[:option_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Option not found" }, status: :not_found
  end

  def vote_response(vote)
    {
      id: vote.id,
      user_id: vote.user_id,
      poll_id: vote.poll_id,
      option_id: vote.option_id,
      created_at: vote.created_at
    }
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
