Exact Wordlist Tab
==============

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0) ![This script was last tested in Nuix 8.4](https://img.shields.io/badge/Script%20Tested%20in%20Nuix-8.4-green.svg)

View the GitHub project [here](https://github.com/Nuix/Exact-Wordlist-Tab) or download the latest release [here](https://github.com/Nuix/Exact-Wordlist-Tab/releases).

# Overview

Ever wanted to do have a word list that is case sensitive and powerful enough to be filtered by various criteria?

# Getting Started

## Setup

Begin by downloading the latest release of this code.
Extract the contents of the archive into your Nuix scripts directory.
In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

Leave the .nuixscript as the extension of the directory.
Then run using the scripts\Exact Wordlist Tab

# Filters
Most people are wanting this feature for password lists. So this tool will allow the filters to assist with that workflow.

Text - The Text object you would see if you view the text tab, clicking this will include the text in the results
Properties - The properties you would see in the metadata of the item, both keys and their values are included in the results
Uppercase - At least one Uppercase letter must be found in the term: /[A-Z]/
Lowercase - At least one Lowercase letter must be found in the term: /[a-z]/
Number - At least one Number must be found in the term: /[0-9]/
Symbol - At least one Symbol must be found in the term(excluding space!): /\W/
Minimum length - Terms are only returned that are equal or greater then the length supplied
Maximum length - Terms are only returned that are equal or less then the length supplied
Note:Terms are limited from 3 to 32 lengths, do not include spaces, lines or tabs

# Export View
After specifying your Filters and the results view populated you can then click the Export View button 
Export will be in CSV with the sort order of your view.

# Double Click Action
Double clicking an item will launch a new workbench searching for that 'exact term' in your case.

Warning:If you have not processed your case with exact queries enabled this will return all items with whitespace inclusive and not the expected results

![Exact Wordlist Tab_screenshot](https://raw.githubusercontent.com/Nuix/Exact-Wordlist-Tab/master/images/Exact%20Wordlist%20Tab_screenshot.PNG)

## License

```
Copyright 2019 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
