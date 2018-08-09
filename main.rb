require "mechanize"
require "pry"
require "csv"

# Settings
asp = YAML.load_file("asp.yml")
security = YAML.load_file("security.yml")
USER_AGENT = "Windows Mozilla"
affiliates = []
security.keys.each {|afi| affiliates << afi if security[afi]["id"]}

agent = Mechanize.new
agent.user_agent = USER_AGENT

# CSV
CSV.open("data.csv", "w") do |csv|
  csv << ["ASP名", "発生件数(本日)", "発生報酬(本日)", "承認件数(本日)", "承認報酬(本日)", "発生件数(当月)", "発生報酬(当月)", "承認件数(当月)", "承認報酬(当月)"]
end

affiliates.each do |afi|
  login_page = asp[afi]["login"]
  data_page  = asp[afi]["data"]

  login_id = security[afi]["id"]
  password = security[afi]["password"]

  puts "#{afi} のデータを検索中です。"

  agent.get(login_page) do |page|
    case afi
    when "a8"
      form = page.form_with(name: "asLogin") do |f|
        f.login = login_id
        f.passwd = password
      end
      form.submit

      # unconfirmed => u, decided => d
      # month => m, daily => d
      actions = ["ud", "dd", "um", "dm"]
      actions.each do |action|
        latest_data_line = ["um", "dm"].include?(action) ? 1 : 2
        search_target = (action == "dd") ? "table" : ".reportTable1"

        count_line = 0
        reward_line = 0
        case action
        when "ud"
          count_line = 5
          reward_line = 6
        when "dd", "um"
          count_line = 3
          reward_line = 4
        when "dm"
          count_line = 1
          reward_line = 2
        end

        _page = agent.get("#{data_page}?action=#{action}")
        target = _page.search(search_target)
        latest_data = target.search("tr")[latest_data_line]
        instance_variable_set("@#{action}_count",  latest_data.search("td")[count_line].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, ""))
        instance_variable_set("@#{action}_reward", latest_data.search("td")[reward_line].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, ""))
      end
    when "felmat"
      form = page.form_with(name: "loginForm") do |f|
        f.p_username = login_id
        f.p_password = password
      end
      form.submit

      actions = ["daily", "monthly"]
      actions.each do |action|
        _page = agent.get("#{data_page}/#{action}")
        target = _page.search("tbody")[0]
        latest_data = target.search("tr")[0]
        term = action == "daily" ? "d" : "m"
        instance_variable_set("@u#{term}_count", latest_data.search("td")[4].text)
        instance_variable_set("@u#{term}_reward", latest_data.search("td")[5].text)
        instance_variable_set("@d#{term}_count", latest_data.search("td")[7].text)
        instance_variable_set("@d#{term}_reward", latest_data.search("td")[8].text)
      end
    when "access_trade"
      form_action = "https://member.accesstrade.net/atv3/login.html"
      form = page.form_with(action: form_action) do |f|
        f.userId = login_id
        f.userPass = password
      end
      form.submit

      _page = agent.get(data_page)
      target = _page.search(".report tbody tr")
      @ud_count  = target[1].search("td")[0].text
      @um_count  = target[1].search("td")[1].text
      @ud_reward = target[2].search("td")[0].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, "")
      @um_reward = target[2].search("td")[1].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, "")
      @dd_count  = target[3].search("td")[0].text
      @dm_count  = target[3].search("td")[1].text
      @dd_reward = target[4].search("td")[0].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, "")
      @dm_reward = target[4].search("td")[1].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, "")
    when "mosimo"
      form = page.form_with(id: "login-form") do |f|
        f.account = login_id
        f.password = password
      end
      form.submit

      actions = ["daily", "monthly"]
      actions.each do |action|
        _page = agent.get("#{data_page}/#{action}")
        target = _page.search(".payment-table tbody")[0].search("tr").last
        term = action == "daily" ? "d" : "m"
        instance_variable_set("@u#{term}_count", target.search("td")[3].search("p")[0].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, ""))
        instance_variable_set("@u#{term}_reward", target.search("td")[3].search("p")[1].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, ""))
        instance_variable_set("@d#{term}_count", target.search("td")[4].search("p")[0].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, ""))
        instance_variable_set("@d#{term}_reward", target.search("td")[4].search("p")[1].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, ""))
      end
    when "rentracks"
      form_action = "https://manage.rentracks.jp/manage/login/login_manage_validation"
      form = page.form_with(action: form_action) do |f|
        f.idMailaddress = login_id
        f.idLoginPassword = password
      end
      form.submit
      _page = agent.get(data_page)
      target = _page.search(".datatable tr")

      actions = ["daily", "monthly"]
      actions.each do |action|
        term = action == "daily" ? "d" : "m"
        instance_variable_set("@u#{term}_count", target[4].search("td")[3].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, ""))
        instance_variable_set("@u#{term}_reward", target[9].search("td")[3].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, ""))
        instance_variable_set("@d#{term}_count", target[7].search("td")[3].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, ""))
        instance_variable_set("@d#{term}_reward", target[10].search("td")[3].text.gsub(/\r\n|\r|\n|\s|\t/, "").gsub(/[^\d]/, ""))
      end
    else
      raise "対応していません"
    end

    puts "#{afi} のデータ検索を終了しました"

    CSV.open("data.csv", "a") do |csv|
      csv << [afi, @ud_count, @ud_reward, @dd_count, @dd_reward, @um_count, @um_reward, @dm_count, @dm_reward]
    end
  end
end

puts "全ての出力が完了しました！ data.csv をチェック！"
