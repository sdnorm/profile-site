class DateParserController < ApplicationController
  include Unindexed

  def index
  end

  def parse
    @phrase = params[:nlp_date]
    @parsed_date = DateParser.parse(@phrase)

    respond_to do |format|
      format.turbo_stream
    end
  end
end
