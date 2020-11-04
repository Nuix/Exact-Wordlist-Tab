import javax.swing.JPanel
import javax.swing.GroupLayout
import javax.swing.JLabel
import javax.swing.JTable
import javax.swing.JScrollPane
import java.awt.Dimension
import javax.swing.JCheckBox
import javax.swing.JComboBox
import javax.swing.JProgressBar
import javax.swing.JButton
import javax.swing.SwingUtilities
import com.teamdev.jxbrowser.chromium.Browser;
import com.teamdev.jxbrowser.chromium.swing.BrowserView;
import javax.swing.JFileChooser
$controls=Hash.new()
$sticky_settings={"Text"=>"true","Properties"=>"false","Uppercase"=>"true","Lowercase"=>"true","Number"=>"true","Symbol"=>"true","Minimum length"=>"8","Maximum length"=>"12"}
$config_file="#{File.dirname(__FILE__)}\\settings.conf"


$canceling=false
$stat_pool=Hash.new()
$buffer_thread=Thread.new(){sleep(0.001)}

##first time detection

def loadhelp()
	body=JPanel.new(java.awt.GridLayout.new(0,1))
	browser=Browser.new()
	browser.cookieStorage().deleteAll()
	browserview=BrowserView.new(browser)
	body.add(browserview)
	browser.loadURL("#{File.dirname(__FILE__)}\\Help.html")
	$window.addTab("Help",body)
end


if(!(File.file? $config_file))
	open($config_file,"w") do |f|
		$sticky_settings.each do |key,value|
			f.puts "#{key}:#{value}"
		end
	end
	loadhelp()
	sleep(5)
	## end first time detection
else
	File.readlines($config_file).each do |line|
		key,value=line.strip().split(":",2)
		$sticky_settings[key]=value
	end
end

$sticky_settings.each do | key,value|
	if(value =~ /^\d+$/)
		$sticky_settings[key]=value.to_i
	else
		value=="true" ? $sticky_settings[key]=true : $sticky_settings[key]=false
	end
end

def save_and_refresh()
	puts "Clicked!"
	begin
		open($config_file,"w") do |f|
			$controls.each do |name,control|
				if(control.respond_to? "isSelected")
					f.puts "#{name}:#{control.isSelected}"
				else
					f.puts "#{name}:#{control.getSelectedIndex+3}"
				end
			end
		end
	rescue Exception => ex
		puts ex.message
	end
	stat_gen()
end

def option_panel()
	panel=JPanel.new(java.awt.GridLayout.new(0,11))
	settings=["Text","Properties","Uppercase","Lowercase","Number","Symbol"]
	
	settings.each do | setting|
		cb = JCheckBox.new setting, $sticky_settings[setting]
		cb.setFocusable(false)
		panel.add(cb)
		$controls[setting]=cb
	end
	
	
	settings=[
		["Minimum length",[*3..32]],
		["Maximum length",[*3..32]],
	]
	settings.each do | setting,value|
		#java layout is cramping my style... adding a lazy space rather then actually figuring out why!
		lbl=JLabel.new("  #{setting}")
		panel.add(lbl)
		cb = JComboBox.new value.to_java
		cb.name=setting
		cb.setSelectedIndex($sticky_settings[setting]-3)
		cb.setFocusable(false)
		panel.add(cb)
		$controls[setting]=cb
	end
	
	$controls.each do | name,control|
		control.addItemListener() do | event|
			if(event.getItem.class == JCheckBox)
				save_and_refresh()
			else
				#java voodoo... state change of 1 means selected. Prevents this firing twice.
				if(event.getStateChange()==1)
						save_and_refresh()
				end
			end
		end
	end
	
	panel.setMaximumSize Dimension.new -1, 20
	return panel
end

def footer_panel()
	footer_panel=JPanel.new(java.awt.GridLayout.new(0,2))
	footer_layout=GroupLayout.new(footer_panel)
	footer_panel.setLayout footer_layout
	footer_layout.setAutoCreateGaps(true)
	footer_layout.setAutoCreateContainerGaps(false);
	footer_horizontalSequentialGroups=footer_layout.createSequentialGroup()
	footer_verticalSequentialGroups=footer_layout.createSequentialGroup()
	footer_option_vgroup=footer_layout.createParallelGroup()
	footer_verticalSequentialGroups.addGroup(footer_option_vgroup)
	footer_hgroup=footer_layout.createSequentialGroup()
	footer_horizontalSequentialGroups.addGroup(footer_hgroup)

	
	
	$progress_stat = JProgressBar.new  0, 100
	$progress_stat.setMinimumSize Dimension.new 100, 20
	$progress_stat.setMaximumSize Dimension.new 99999999, 20
	footer_option_vgroup.addComponent($progress_stat)
	footer_hgroup.addComponent($progress_stat)
	
	export_button=JButton.new()
	export_button.setText("Export View")
	export_button.addActionListener { |e|
		filename=save_file("Export to where?","",{"tab separated file (*.tsv)"=>"tsv"})
		if(!filename.nil?)
			if(!filename.end_with? ".tsv")
				filename="#{filename}.tsv"
			end
			#let's do the export
			open(filename,"w") do |f|
				columns=Array.new()
				0.upto($results_table.getModel.getColumnCount()-1) do |i|
					columns.push $results_table.getModel().getColumnName(i)
				end
				f.puts columns.join("\t")
				columncount=$results_table.getModel().getColumnCount()
				rowcount=$results_table.getModel().getRowCount()
				0.upto(rowcount-1) do |row_item_index|
					row=Array.new()
					0.upto(columns.length-1) do |cell|
						row.push $results_table.getModel().getValueAt($results_table.convertRowIndexToModel(row_item_index),cell)
					end
					f.puts row.join("\t")
				end
			end
		end	
	}
	footer_option_vgroup.addComponent(export_button)
	footer_hgroup.addComponent(export_button)
	
	footer_layout.setVerticalGroup(footer_verticalSequentialGroups)
	footer_layout.setHorizontalGroup(footer_horizontalSequentialGroups)
	footer_layout=GroupLayout.new(footer_panel)

	return footer_panel
end


def create_table(columns_Array,rows_Array,name)
	columnnames=java.util.Vector.new()
	columns_Array.each do | column|
		columnnames.add(column)
	end

	rowvalues=java.util.Vector.new()
	rows_Array.each do | row|
		rowvalue=java.util.Vector.new(1)
		row.each do | cell|
			rowvalue.addElement(cell)
		end
		rowvalues.addElement(rowvalue)
	end
	tb = JTable.new(rowvalues,columnnames)
	tb.name=name
	tb.addMouseListener() do | event|
		if(event.getClickCount()==2)
			#java voodoo... event is a double click with an exit (three events are passed only taking one of them)
			if(event.getID()==502)
				rowindex=tb.rowAtPoint(event.getPoint())
				modelrow=tb.convertRowIndexToModel(rowindex)
				modelcolumn=tb.convertColumnIndexToModel(2)
				query="guid:(" + tb.getModel().getValueAt(modelrow,modelcolumn).split(',').join(" OR ") + ")"
				#Define our tab settings
				settings = {
					"search" => query, #The query the tab will run and display results for
				}
				
				#Show our tab which uses our custom profile
				$window.openTab("workbench",settings)
			end
		end
	end
	tb.enabled=false
	return tb
end

def password_capable(string)
	#has 3-32 length, capital letters, lower case letters, number and symbol
	string.length < ($controls["Minimum length"].getSelectedIndex() +3) ? (return false) : nil
	string.length > ($controls["Maximum length"].getSelectedIndex() +3) ? (return false) : nil
	if($controls["Uppercase"].isSelected())
		(string =~ /[A-Z]/) ? nil : (return false)
	end
	if($controls["Lowercase"].isSelected())
		(string =~ /[a-z]/) ? nil : (return false)
	end
	if($controls["Number"].isSelected())
		(string =~ /[0-9]/) ? nil : (return false)
	end
	if($controls["Symbol"].isSelected())
		(string =~ /\W/) ? nil : (return false)
	end
	return true
end


def thread_safe_now(&block)
	SwingUtilities.invokeAndWait(block)
end

def stat_gen()
	if($buffer_thread.alive? ==true)
		$canceling=true
		while ($canceling==true)
			puts "cancelling.."
			sleep(0.1)
		end
		while($buffer_thread.alive?)
			puts "tidying up..."
			sleep(0.1)
		end
	end
	
	puts "#{Time.now} : Pooling results"
	$stat_pool=Hash.new()
	#these should do the same thing...but they really don't!
	$results_table.getModel().setRowCount(0)
	$results_table.getModel().getDataVector().removeAllElements()
	$buffer_thread =Thread.new(){
		items=($current_selected_items.to_a.length==0)  ? $current_case.searchUnsorted("") : $current_selected_items
		$progress_stat.setMaximum(items.length-1)
		items.each_with_index do | item,index|
			begin
				if($canceling==true)
					#cancel request recieved... stop looping and return immediately.
					$canceling=false
					Thread.current.kill
				end
				$progress_stat.setValue(index)
				text=""
				case
				when ($controls["Properties"].isSelected() && $controls["Text"].isSelected())
					props=item.getProperties()
					text=(props.keys.push *props.values).join(" ")
					text="#{text} #{item.getTextObject().toString()}"
				when ($controls["Properties"].isSelected())
					props=item.getProperties()
					text=(props.keys.push *props.values).join(" ")
				when ($controls["Text"].isSelected())
					text=item.getTextObject().toString()
				end
				if(!(text.nil?))
					text.split(/[\ \r\n\t]+/).uniq.select{|word|password_capable(word)}.each do | val|
						if($canceling==true)
							#cancel request recieved... stop looping and return immediately.
							$canceling=false
							Thread.current.kill
						end
						#puts do something about val
						if($stat_pool.has_key? val)
							$stat_pool[val].push(item.getGuid())
						else
							$stat_pool[val]=[item.getGuid()]
						end
					end
				end
			rescue Exception => ex
				puts "WARN: #{ex.message}"
			end
		end
		thread_safe_now do 
			$stat_pool.each do | val,guid_list|
				if($canceling == false)
					rowvalue=java.util.Vector.new(1)
					rowvalue.addElement(val)
					rowvalue.addElement(guid_list.length().to_s.rjust(10, '0'))
					rowvalue.addElement(guid_list.join(","))
					$results_table.getModel().addRow(rowvalue)
				end
			end
		end
		puts "#{Time.now} : Finished pool"
	}
	puts "Queued..."
end


#save_file("some title","c:/",{"comma"=>"csv","text"=>"txt"})
def save_file (title="Choose File",loaddir="",extensions=Hash.new())
	file = nil
	chooser = javax.swing.JFileChooser.new
	chooser.dialog_title = title
	if(extensions.length > 0)
		extensions=extensions.map{|name,ext|javax.swing.filechooser.FileNameExtensionFilter.new(name,ext)}
		extensions.each do |ext| chooser.addChoosableFileFilter(ext) end
		chooser.setFileFilter(extensions.first)
	end
		
	chooser.file_selection_mode = JFileChooser::FILES_ONLY
	chooser.setCurrentDirectory(java.io.File.new("#{loaddir}"))
	if chooser.show_save_dialog(nil) == javax.swing.JFileChooser::APPROVE_OPTION
		file=chooser.selected_file.path
	end
	return file
end

tab_panel=JPanel.new()
tab_layout=GroupLayout.new(tab_panel)
tab_panel.setLayout tab_layout
tab_layout.setAutoCreateGaps(true)
tab_layout.setAutoCreateContainerGaps(true);
tab_horizontalSequentialGroups=tab_layout.createSequentialGroup()
tab_verticalSequentialGroups=tab_layout.createSequentialGroup()
tab_option_vgroup=tab_layout.createParallelGroup()
tab_verticalSequentialGroups.addGroup(tab_option_vgroup)
tab_hgroup=tab_layout.createParallelGroup()
tab_horizontalSequentialGroups.addGroup(tab_hgroup)


tab_option_panel=option_panel()
tab_option_vgroup.addComponent(tab_option_panel)
tab_hgroup.addComponent(tab_option_panel)

tab_main_vgroup=tab_layout.createParallelGroup()
tab_verticalSequentialGroups.addGroup(tab_main_vgroup)
$results_table=create_table(["Exact Word","Number of items","GUIDs"],[[]],"results")
jscroller = JScrollPane.new
jscroller.getViewport.add $results_table
$results_table.setAutoCreateRowSorter(true)
tab_main_vgroup.addComponent(jscroller)
tab_hgroup.addComponent(jscroller)

tab_footer_vgroup=tab_layout.createParallelGroup()
tab_verticalSequentialGroups.addGroup(tab_footer_vgroup)
footer_panel=footer_panel()
tab_footer_vgroup.addComponent(footer_panel)
tab_hgroup.addComponent(footer_panel)


tab_layout.setVerticalGroup(tab_verticalSequentialGroups)
tab_layout.setHorizontalGroup(tab_horizontalSequentialGroups)

tab_layout=GroupLayout.new(tab_panel)

$window.addTab("Exact Word List",tab_panel)
stat_gen()

away=false
invalid_secs=0
while(true)
	sleep(1)
	if(!tab_panel.getParent().isVisible())
		if(away==true)
			#puts "user has navigated away from this tab..."
		end
		away=false
	else
		if(away==false)
			#puts "user has navigated back to this tab... should I refresh?"
		end
		away=true
	end
	if($results_table.to_s.include? "invalid")
		invalid_secs=invalid_secs+1
		if(invalid_secs > 5)
			#bit of a long story here... so to keep it short the table does go invalid briefly when shifting between tabs... So... wait a few seconds to be sure the table remains invalid.
			puts "Closed Exact Wordlist Tab"
			exit
		end
	else
		invalid_secs=0
	end
end

