
$:.unshift File.dirname(__FILE__) + '/../lib'
require 'rubygems'
require 'eventmachine'

require 'test/unit'
require 'wakame'
require 'wakame/manager/scheduler'

WAKAME_ROOT="#{File.dirname(__FILE__)}/.."

class TestScheduler < Test::Unit::TestCase
  include Wakame::Manager

  def test_sequence
    seq = Scheduler::TimedSequence.new
    seq.start_at = Time.now

    seq[0]=1
    seq[30]=3
    seq[780]=1
    seq[110]=2
    seq[320]=4

    p seq
    p seq.duration
    p (seq.start_at + seq.duration)

    seq2 = Scheduler::PerMinuteSequence.new
    seq2.start_at = Time.now

    seq2[0]=1
    seq2[20]=2
    seq2[59]=2
    seq2[10]=3
    seq2[15]=8
    seq2[30]=4
    seq2[55]=3
    seq2[5]=8
    seq2[2930]=1
    seq2[430]=1
    seq2[3430]=3
    seq2[1410]=1
    seq2[159]=2

    #assert_equal([0, 5, 10, 15, 20, 30, 55, 59], seq2.keys)
    assert(seq2.duration == 60)
    assert(seq2.range_check?(seq2.start_at))
    assert(seq2.range_check?(seq2.start_at + 0.0))
    assert(seq2.range_check?(seq2.start_at + 59.0))
    assert(seq2.range_check?(seq2.start_at + 59.1))
    assert(seq2.range_check?(seq2.start_at + 59.9))
    assert(seq2.range_check?(seq2.start_at + 60.0) == true )
    assert(seq2.range_check?(seq2.start_at - 1.0) == false )
    assert_equal(1, seq2.value_at(seq2.start_at))
    assert_equal(1, seq2.value_at(seq2.start_at + 0.0))
    assert_equal(1, seq2.value_at(seq2.start_at + 2.0))
    assert_equal(2, seq2.value_at(seq2.start_at + 59.0))
    assert_equal(2, seq2.value_at(seq2.start_at + 59.32939))
    assert_equal(2, seq2.value_at(seq2.start_at + 60.0))
    assert_equal(nil, seq2.value_at(seq2.start_at + 61.0))
    assert_equal(nil, seq2.value_at(seq2.start_at + 99999.0))
    assert_equal([5.0, 8], seq2.next_event(seq2.start_at) )
    assert_equal([5.0, 8], seq2.next_event(seq2.start_at + 0.0) )
    assert_equal([4.0, 8], seq2.next_event(seq2.start_at + 1.0) )
    assert_equal([5.0, 3], seq2.next_event(seq2.start_at + 5.0) )
    assert_equal([1.0, 3], seq2.next_event(seq2.start_at + 9.0) )
    assert_equal([1.0, 8], seq2.next_event(seq2.start_at + 14.0) )
    assert_equal([4.0, 2], seq2.next_event(seq2.start_at + 55.0) )
    assert_equal([1.0, 2], seq2.next_event(seq2.start_at + 58.0) )
    assert_equal(nil, seq2.next_event(seq2.start_at + 59.0) )
    assert_equal(nil, seq2.next_event(seq2.start_at + 59.1883) )
    assert_equal(nil, seq2.next_event(seq2.start_at + 60.0) )
    assert_equal(nil, seq2.next_event(seq2.start_at + 99999.0) )

    
    seq = Scheduler::LoopSequence.new(seq2)
    
    check_at = seq2.start_at + 360.0
    assert_equal(1, seq.value_at(check_at))
    assert_equal(1, seq.value_at(check_at + 0.0))
    assert_equal(1, seq.value_at(check_at + 2.0))
    assert_equal(8, seq.value_at(check_at + 10.0))
    assert_equal(3, seq.value_at(check_at + 10.88393))
    assert_equal(2, seq.value_at(check_at + 59.0))
    assert_equal(2, seq.value_at(check_at + 59.32939))
    assert_equal(2, seq.value_at(check_at + 60.0))
    assert_equal(1, seq.value_at(check_at + 61.0))
    assert_equal(1, seq.value_at(check_at + 361.0))
    assert_equal([5.0, 8], seq.next_event(check_at) )
    assert_equal([5.0, 8], seq.next_event(check_at + 0.0) )
    assert_equal([4.0, 8], seq.next_event(check_at + 1.0) )
    assert_equal([5.0, 3], seq.next_event(check_at + 5.0) )
    assert_equal([1.0, 3], seq.next_event(check_at + 9.0) )
    assert_equal([1.0, 8], seq.next_event(check_at + 14.0) )
    assert_equal([4.0, 2], seq.next_event(check_at + 55.0) )
    assert_equal([1.0, 2], seq.next_event(check_at + 58.0) )
    assert_equal([4.0, 2], seq.next_event(check_at + 55.0) )


    seq2 = Scheduler::PerMinuteSequence.new
    seq2.start_at = Time.now
    seq2[0]=1

    seq = Scheduler::LoopSequence.new(seq2)
    
    check_at = seq2.start_at + 360.0
    assert_equal(1, seq.value_at(check_at))
    assert_equal(1, seq.value_at(check_at + 0.0))
    assert_equal(1, seq.value_at(check_at + 2.0))
    assert_equal(1, seq.value_at(check_at + 10.0))
    assert_equal(1, seq.value_at(check_at + 61.0))
    assert_equal(1, seq.value_at(check_at + 361.0))
    assert_equal([60.0, 1], seq.next_event(check_at) )
    assert_equal([60.0, 1], seq.next_event(check_at + 0.0) )
    assert_equal([59.0, 1], seq.next_event(check_at + 1.0) )
    assert_equal([25.0, 1], seq.next_event(check_at + 35.0) )
    assert_equal([1.0, 1], seq.next_event(check_at + 59.0) )
    assert_equal([0.0, 1], seq.next_event(check_at + 60.0) )
    assert_equal([59.0, 1], seq.next_event(check_at + 61.0) )

  end
end
