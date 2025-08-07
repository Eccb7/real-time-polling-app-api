class PollsChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe to general polls updates
    stream_from "polls_channel"

    # Subscribe to specific poll if poll_id is provided
    if params[:poll_id].present?
      poll = Poll.find_by(id: params[:poll_id])
      if poll
        stream_from "poll_#{poll.id}"
      else
        reject
      end
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end

  def subscribe_to_poll(data)
    poll_id = data["poll_id"]
    poll = Poll.find_by(id: poll_id)

    if poll
      stream_from "poll_#{poll.id}"
      transmit({
        type: "subscription_confirmed",
        poll_id: poll.id,
        message: "Subscribed to poll: #{poll.title}"
      })
    else
      transmit({
        type: "error",
        message: "Poll not found"
      })
    end
  end

  def unsubscribe_from_poll(data)
    poll_id = data["poll_id"]
    stop_stream_from "poll_#{poll_id}"
    transmit({
      type: "unsubscription_confirmed",
      poll_id: poll_id,
      message: "Unsubscribed from poll"
    })
  end
end
