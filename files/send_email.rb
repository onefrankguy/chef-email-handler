require 'net/smtp'
require 'digest'
require 'time'

module BeFrank
  class SendEmail < Chef::Handler
    def report
      now = ::Time.now.utc.iso8601
      name = node.name

      subject = "Good Chef run on #{name} @ #{now}"
      message = "It's all good."

      if failed?
        subject = "Bad Chef run on #{name} @ #{now}"
        message = [run_status.formatted_exception]
        message += ::Array(backtrace).join("\n")
      end

      send_new_email(
        :subject => subject,
        :body => message
      )
    end

    private

    def send_new_email data = {}
      cache = Chef::Config[:file_cache_path]
      cache = ::File.join cache, 'last_run.digest'

      last_digest = nil
      if ::File.exists? cache
        last_digest = ::File.read cache
      end

      # This works around an issue in Ruby 1.8
      # where Hashes don't enumerate their values
      # in a guaranteed order.
      data = data.keys.sort.map do |k|
        [k, data[k]]
      end

      digest = ::Digest::SHA256.hexdigest data.to_s
      ::File.open(cache, 'w') do |io|
        io << digest
      end

      if digest != last_digest
        send_email ::Hash[data]
      end
    end

    def send_email options = {}
      options[:subject] ||= 'Hello from Chef'
      options[:body] ||= '...'
      options[:from] ||= 'chef@example.com'
      options[:from_alias] ||= 'Chef Client'
      options[:to] ||= 'you@example.com'
      options[:server] ||= 'localhost'

      from = options[:from]
      to = options[:to]

      message = <<-EOM
      From: #{options[:from_alias]} <#{from}>
      To: #{to}
      Subject: #{options[:subject]}

      #{options[:body]}
      EOM

      message = unindent message

      ::Net::SMTP.start(options[:server]) do |smtp|
        smtp.send_message message, from, to
      end
    end

    def unindent string
      first = string[/\A\s*/]
      string.gsub /^#{first}/, ''
    end
  end
end
