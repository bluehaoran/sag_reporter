class StateLanguage < ActiveRecord::Base

  belongs_to :geo_state
  belongs_to :language
  has_many :language_progresses, dependent: :destroy
  has_many :progress_updates, through: :language_progresses

  delegate :name, to: :language, prefix: true
  delegate :name, to: :geo_state, prefix: 'state'
  delegate :colour, to: :language, prefix: true
  delegate :zone, to: :geo_state

  validates :geo_state, presence: true
  validates :language, presence: true

  scope :in_project, -> { where project: true }

  def <=>(sl)
    language.name.downcase <=> sl.language.name.downcase
  end

  def outcome_table_data(options = {})
    options[:from_date] ||= 6.months.ago
    options[:to_date] ||= Date.today

    table = Hash.new
    table['content'] = Hash.new
    table['Totals'] = Hash.new {0}

    all_lps = language_progresses.includes({:progress_marker => :topic}, :progress_updates)
    all_lps.each do |lp|
      oa_name = lp.progress_marker.topic.name
      table['content'][oa_name] ||= Hash.new {0}
      lp.outcome_scores(options[:from_date], options[:to_date]).each do |date, score|
        table['content'][oa_name][date] += score
        table['Totals'][date] += score
      end
    end
    if table['content'].any?
      # now express all scores as a percentage of the maximum attainable
      total_divisor = 0
      Topic.find_each do |oa|
        divisor = max_outcome_score(oa)
        if !(divisor > 0)
          divisor = 1
        end
        total_divisor += divisor
        if table['content'][oa.name]
          table['content'][oa.name].each do |date, score|
            table['content'][oa.name][date] = (score * 100).fdiv(divisor)
          end
        end
      end
      table['Totals'].each do |date, score|
        table['Totals'][date] = (score * 100).fdiv(total_divisor)
      end
      return table
    else
      return nil
    end
  end

  # convert the table data into a format ChartKick can use
  def outcome_chart_data(options = {})
    table_data = outcome_table_data(options)
    if table_data
      chart_data = Array.new
      table_data['content'].each do |row_name, table_row|
        chart_row = {name: row_name, data: table_row}
        chart_data.push(chart_row)
      end
      overall_row = {name: 'Overall score', data: table_data['Totals']}
      chart_data.push(overall_row)
      return chart_data
    else
      return nil
    end
  end

  # The maximum outcome score for a given outcome area
  # discounting all the progress markers where this
  # state_language has not set levels.
  def max_outcome_score(outcome_area)
    score = 0
    language_progresses.with_updates.
        includes(:progress_marker).
        where('progress_markers.topic_id' => outcome_area.id).
        find_each do |progress|
      score += progress.progress_marker.weight  * ProgressMarker.spread_text.keys.max
    end
    return score
  end

end
