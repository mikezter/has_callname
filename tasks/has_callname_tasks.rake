
namespace :callnames do
  desc "generate callnames for a given model"
  task :generate, :model, :needs => :environment do |t, args|
    puts "Generating callnames for #{args[:model].camelize}"
    args[:model].camelize.constantize.all.each do |instance|
      instance.save!
    end
  end
end

