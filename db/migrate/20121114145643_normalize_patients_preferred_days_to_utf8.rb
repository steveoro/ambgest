class NormalizePatientsPreferredDaysToUtf8 < ActiveRecord::Migration

  PREFIXES_FOR_DAYS = [ 'luned', 'marted', 'mercoled', 'gioved', 'venerd' ]


  def up
    say "Correcting all non-UTF8 day names inside 'Patient.preferred_days'..."

    Patient.transaction do                          # -- START TRANSACTION --
      PREFIXES_FOR_DAYS.each { |day_prefix|
        results = Patient.where("preferred_days LIKE '%#{day_prefix}Ã¬%'")
        results.each{ |row|
          row.preferred_days = row.preferred_days.gsub( /#{day_prefix}Ã¬/i, "#{day_prefix}ì" )
          row.save
        }
      }
    end                                             # -- END TRANSACTION --
    say 'Done.'
  end


  def down
    say "Restoring all UTF8 day names inside 'Patient.preferred_days' to something readable..."

    Patient.transaction do                          # -- START TRANSACTION --
      PREFIXES_FOR_DAYS.each { |day_prefix|
        results = Patient.where("preferred_days LIKE '%#{day_prefix}ì%'")
        results.each{ |row|
          row.preferred_days = row.preferred_days.gsub( /#{day_prefix}ì/i, "#{day_prefix}i'" )
          row.save
        }
      }
    end                                             # -- END TRANSACTION --
    say 'Done.'
  end
end
