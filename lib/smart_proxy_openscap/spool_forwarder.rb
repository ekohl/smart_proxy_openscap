module Proxy::OpenSCAP
  class SpoolForwarder
    include ::Proxy::Log

    def post_arf_from_spool(arf_dir)
      Dir.foreach(arf_dir) do |cname|
        next if cname == '.' || cname == '..'
        cname_dir = File.join(arf_dir, cname)
        forward_cname_dir(cname, cname_dir) if File.directory?(cname_dir)
      end
    end

    private

    def forward_cname_dir(cname, cname_dir)
      Dir.foreach(cname_dir) do |policy_id|
        next if policy_id == '.' || policy_id == '..'
        policy_dir = File.join(cname_dir, policy_id)
        if File.directory?(policy_dir)
          forward_policy_dir(cname, policy_id, policy_dir)
        end
      end
      remove(cname_dir)
    end

    def forward_policy_dir(cname, policy_id, policy_dir)
      Dir.foreach(policy_dir) do |date|
        next if date == '.' || date == '..'
        date_dir = File.join(policy_dir, date)
        if File.directory?(date_dir)
          forward_date_dir(cname, policy_id, date, date_dir)
        end
      end
      remove(policy_dir)
    end

    def forward_date_dir(cname, policy_id, date, date_dir)
      path = upload_path(cname, policy_id, date)
      Dir.foreach(date_dir) do |arf|
        next if arf == '.' || arf == '..'
        arf_path = File.join(date_dir, arf)
        if File.file?(arf_path)
          logger.debug("Uploading #{arf} to #{path}")
          forward_arf_file(cname, policy_id, date, arf_path)
        end
      end
      remove(date_dir)
    end

    def forward_arf_file(cname, policy_id, date, arf_file_path)
      data = File.read(arf_file_path)
      ForemanForwarder.new.post_arf_report(cname, policy_id, date, data)
      File.delete arf_file_path
    end
  end
end
