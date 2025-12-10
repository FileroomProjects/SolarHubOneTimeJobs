#!/usr/bin/env ruby

# Test script to verify the sync works with a single job
require_relative 'sync_jobs'

# Load .env file if it exists (for local development)
begin
  require 'dotenv'
  Dotenv.load if File.exist?('.env')
rescue LoadError
  # dotenv not available, using environment variables directly
end

class TestJobsSync < JobsSync
  def run_test
    puts "=" * 80
    puts "Testing Jobs Sync (Single Job)"
    puts "=" * 80
    puts ""
    
    # Test connection to Simpro
    puts "1. Testing Simpro connection..."
    jobs = fetch_test_job_from_simpro
    
    if jobs.nil? || jobs.empty?
      puts "❌ Failed to fetch jobs from Simpro"
      return
    end
    
    puts "✅ Successfully connected to Simpro"
    puts "   Found #{jobs.count} jobs (will process first one only)"
    puts ""
    
    # Process first job
    job = jobs.first
    puts "2. Testing job processing..."
    puts "   Job ID: #{job['ID']}"
    puts "   Job Name: #{job['Name']}"
    puts ""
    
    process_job(job)
    
    puts ""
    puts "=" * 80
    puts "Test Summary"
    puts "=" * 80
    puts "Created: #{@stats[:created]}"
    puts "Updated: #{@stats[:updated]}"
    puts "Failed: #{@stats[:failed]}"
    puts ""
    
    if @stats[:failed] > 0
      puts "❌ Test failed - check logs for details"
    elsif @stats[:created] > 0 || @stats[:updated] > 0
      puts "✅ Test successful!"
    else
      puts "⚠️  Test completed but no jobs were created or updated"
    end
  end
  
  private
  
  def fetch_test_job_from_simpro
    rate_limit_simpro
    
    response = with_retry do
      HTTParty.get(
        "#{@simpro_url}/jobs/",
        query: { page: 0, pageSize: 1 },
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@simpro_key}"
        },
        timeout: 60
      )
    end
    
    response.success? ? response.parsed_response : nil
  end
end

# Run the test
if __FILE__ == $0
  test_sync = TestJobsSync.new
  test_sync.run_test
end

