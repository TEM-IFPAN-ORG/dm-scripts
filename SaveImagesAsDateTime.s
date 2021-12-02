void SaveAsFnDateTime()
{
	number n_imgs = CountImages()
	if(n_imgs == 0)
	{
		OkDialog("There are no images to save!")
		return
	}
	
	for(number i=0; i<n_imgs; i++)
	{
		image img := GetFrontImage()
		string img_name = GetName(img)
		taggroup img_tags = img.ImageGetTagGroup()
		
		string date_tag_group = "DataBar:Acquisition Date"
		string time_tag_group = "DataBar:Acquisition Time"
			
		string date, time
		
		img_tags.TagGroupGetTagAsString(date_tag_group, date)
		img_tags.TagGroupGetTagAsString(time_tag_group, time)
		
		string fix_date = ""
		string fix_time = ""
		
		for(Number j=1; j<=len(date); j++)
		{
			string c = date.left(j).right(1)
			
			if(c != "/")
			{
				fix_date += date.left(j).right(1)
			}
			else
			{
				fix_date += "-"
			}
		}
		
		for(Number j=1; j<=len(time); j++)
		{
			string c = time.left(j).right(1)
			
			if(c != ":" && c != " ")
			{
				fix_time += time.left(j).right(1)
			}
			else
			{
				fix_time += "_"
			}
		}
		
		// OkDialog("Acquisition date = " + date)
		// OkDialog("Acquisition time = " + time)
		
		string new_img_name = img_name + "_" + fix_date + "_" + fix_time
		
		string curr_dir = GetApplicationDirectory(2, 0)
		string save_path = PathConcatenate(curr_dir, new_img_name)
		save_path += ".dm3"
		// OkDialog(save_path)
		SaveAsGatan(img, save_path)
		
		ImageDocument img_doc = GetImageDocument(0)
		ImageDocumentClose(img_doc, 0)
	}
}

// -------------------------------------------------------------------

class CreateButtonDialog : uiframe
{
	void SaveButtonResponse(object self)
	{
		SaveAsFnDateTime()
	}
}

// -------------------------------------------------------------------

/*
taggroup MakeButton()
{
	TagGroup save_button = DlgCreatePushButton("Save all with date/time", "SaveButtonResponse")
	save_button.DlgExternalPadding(10, 10)
	return save_button
}
*/

// -------------------------------------------------------------------

taggroup MakePanel()
{		
	taggroup panel = DlgCreatePanel()
	taggroup save_button = DlgCreatePushButton("Save all with date/time", "SaveButtonResponse")
	panel.DlgAddElement(save_button)
	return panel
}

// -------------------------------------------------------------------

void CreateSaveDialog()
{
	taggroup position;
	position = DlgBuildPositionFromApplication()
	position.TagGroupSetTagAsTagGroup("Width", DlgBuildAutoSize())
	position.TagGroupSetTagAsTagGroup("Height", DlgBuildAutoSize())
	position.TagGroupSetTagAsTagGroup("X", DlgBuildRelativePosition("Inside", 1))
	position.TagGroupSetTagAsTagGroup("Y", DlgBuildRelativePosition("Inside", 1))

	taggroup dialog_items
	taggroup dialog = DlgCreateDialog("SaveAsDT Widget", dialog_items).DlgPosition(position)
	
	dialog_items.DlgAddElement(MakePanel())
	// dialog_items.DlgAddelement(MakeButton())
		
	object dialog_frame = alloc(CreateButtonDialog).init(dialog)
	dialog_frame.display("SaveAsDT Widget")
}

// -------------------------------------------------------------------

CreateSaveDialog()