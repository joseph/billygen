module Billygen

  # Attributes that RDoc native objects will need so we know we've touched them.
  module RDocObjectAttributes

    attr_accessor :billy_id, :billy_object

  end


  class RDocWorkarounds

    # We'll add a few attributes to RDoc CodeObjects, so that we can keep track
    # of them as we generate the output.
    def self.apply_monkey_patches
      [RDoc::CodeObject, RDoc::Context::Section].each { |klass|
        klass.class_eval { include Billygen::RDocObjectAttributes }
      }
    end


    # Assorted cleanups that happen after the RDoc data has been hashed up,
    # and before it is saved to YAML.
    def self.postprocess
      repair_parents
      repair_superclasses
      repair_included_modules
      generate_full_names
    end


    # This should be unnecessary. Sometimes a parent is not recognised during
    # processing. We can go through all such orphans and try to find their 
    # parents.
    def self.repair_parents
      classes_and_modules = Billygen::CodeObjects::BClass.store + 
        Billygen::CodeObjects::BModule.store
      orphans = classes_and_modules.select {|klass| !klass.parent }

      orphans.each { |orphan|
        parent = classes_and_modules.detect { |obj| 
          obj.modules.include?(orphan) ||
          obj.classes.include?(orphan) 
        }
        if parent
          orphan.instance_variable_set(:@parent_id, parent.id)
          orphan.instance_variable_set(:@parent_collection, parent.class.key)
          puts "Associated #{orphan.full_name} with parent #{parent.full_name}"
        end
      }
    end


    # Yeah this is a hack. It gets around an RDoc bug, where it fails to
    # provide a superclass object if it's in the same file as this class --
    # giving just a name instead.
    #
    # Of course this workaround is imperfect, because the RDoc superclass
    # name is not fully qualified. So if you have a class called
    # Billygen::Object for example, then all subclasses of Ruby's core 
    # Object class will be considered a subclass of that class instead. Ugh.
    #
    # FIXME: how do we remove replaced classes from the store without screwing
    # up the index? Ugh.
    def self.repair_superclasses
      all_classes = Billygen::CodeObjects::BClass.store
      all_real_classes = all_classes.select { |klass| !klass.external? }

      all_classes.each { |klass|
        next unless klass.external?

        rep_klass = all_real_classes.find { |rep| rep.name == klass.name }

        next unless rep_klass

        puts "Replacement found: #{klass.name} -> #{rep_klass.name}"

        klass.subclasses.each { |sub|
          sub.instance_variable_set(:@superclass_id, rep_klass.id)
        }
      }
    end


    # RDoc gives us a string (module name) for external modules. But for 
    # internal modules, somehow we always get the same RDoc module object,
    # that is not the module which is being included. Since the module *name*
    # we get is correct - only the object isn't - this looks like a typo in
    # the RDoc source. But until we can track it down, we'll just adjust
    # the data in postprocessing.
    def self.repair_included_modules
      all_includes = Billygen::CodeObjects::BInclude.store
      all_modules = Billygen::CodeObjects::BModule.store

      all_includes.each { |inc|
        next if inc.module.is_a?(String)
        if inc.module.full_name != inc.name
          mod = all_modules.find {|mod| mod.full_name == inc.name}
          inc.instance_variable_set(:@module_id, mod ? mod.id : inc.name)
        end
      }
    end

    def self.generate_full_names
      all_modules = Billygen::CodeObjects::BModule.store
      all_classes = Billygen::CodeObjects::BClass.store
      (all_modules + all_classes).each { |obj| obj.full_name }
    end

  end

end
