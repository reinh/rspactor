require 'osx/cocoa'

class SpecTable < OSX::NSObject
  include OSX
  
  ib_outlet :specsTable

  
  def awakeFromNib
    Notification.subscribe self, :spec_run_processed          => :specRunFinishedSingleSpec
    Notification.subscribe self, :first_failed_spec           => :markFileContainingFirstFailedSpec
    Notification.subscribe self, :file_table_reload_required  => :reload_required
    
    @specsTable.setTarget(self)
    @specsTable.setAction(:selectFileAndLoadView)
    @specsTable.setDoubleAction(:addSelectedFileToRunnerQueue)
  end
  
  def markFileContainingFirstFailedSpec(notification)    
    @selectedSpecFile = notification.userInfo.first.file_object
  end
  
  def selectFileAndLoadView(sender)
    @selectedSpecFile = ExampleFiles.file_by_index(@specsTable.selectedRow)
    Notification.send :fileToWebViewLoadingRequired, @specsTable
  end
  
  def addSelectedFileToRunnerQueue(sender)
    @selectedSpecFile = ExampleFiles.file_by_index(@specsTable.selectedRow)
    if @selectedSpecFile
      SpecRunner.queue << @selectedSpecFile.path    
      SpecRunner.process_queue 
    end
  end
  
  def specRunFinishedSingleSpec(notification)
    reload!
  end
  
  def reload_required(notification)
    reload!
  end
  
  def reload!
    @specsTable.reloadData
    if @selectedSpecFile
      index = ExampleFiles.index_for_file(@selectedSpecFile)
      Notification.send :retain_focus_on_drawer
      @specsTable.selectRowIndexes_byExtendingSelection(NSIndexSet.new.initWithIndex(index), false)
    end
  end
  
  def numberOfRowsInTableView(specTable)
    ExampleFiles.files_count
  end

  def tableView_objectValueForTableColumn_row(specTable, specTableColumn, rowIndex)
    return unless file = ExampleFiles.file_by_index(rowIndex)
    return unless file.name
    file.name(:include => :spec_count).colored(color_by_state(file))
  end

  def color_by_state(spec_file)
    if spec_file.failed?
      { :red => 0.8, :green => 0.1, :blue => 0.1 }
    elsif spec_file.pending?
      { :red => 0.9, :green => 0.6, :blue => 0.0 }
    elsif spec_file.passed?
      { :red => 0.0, :green => 0.3, :blue => 0.0 }
    else
      { :red => 0.2, :green => 0.2, :blue => 0.2 }
    end
  end
end
