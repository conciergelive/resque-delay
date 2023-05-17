# resque-delay

Allows you to call .send_later or .delay.method on objects à la DelayedJob

    # Instead of calling your mailer inline
    MyMailer.deliver_notice
    
    # send it to resque:
    MyMailer.delay.deliver_notice

# Installation

    $ gem install resque-delay

Or add it to your Gemfile and `bundle`.

# Version Notes

Rails versions 2.3, 3.x, and 4.x are currently supported.

- Rails 2.3 - use `rails-2` branch
- Rails 3.x/4.x - use `main` branch

# Author

Michael Rykov :: mrykov@gmail.com
