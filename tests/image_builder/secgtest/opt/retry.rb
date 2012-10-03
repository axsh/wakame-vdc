# encoding: utf-8

module RetryHelper
  #include Config
  
  DEFAULT_WAIT_PERIOD=60*5
  
  def retry_while_not(wait_sec=DEFAULT_WAIT_PERIOD, &blk)
    start_at = Time.now
    lcount=0
    loop {
      if blk.call
        raise("Retry Failure: block returned true. Retried #{lcount} times")
      else
        sleep 2
      end
      lcount += 1
      break if (Time.now - start_at) > wait_sec
    }
  end
  
  def retry_until(wait_sec=DEFAULT_WAIT_PERIOD, &blk)
    start_at = Time.now
    lcount=0
    loop {
      if blk.call
        break
      else
        sleep 2
      end
      lcount += 1
      raise("Retry Failure: Exceed #{wait_sec} sec: Retried #{lcount} times") if (Time.now - start_at) > wait_sec
    }
  end

  def retry_while(wait_sec=DEFAULT_WAIT_PERIOD, &blk)
    retry_until(wait_sec) do
      !blk.call
    end
  end
end
