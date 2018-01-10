#!/usr/bin/env php
<?php
	$version="1.4";
	// load file into a string
	$gcode = strtoupper(file_get_contents($_SERVER["argv"][1]));

	// strip whitespace
	$gcode = str_replace(' ', '', $gcode);

	function check_array($array, $string)
	{
		foreach ($array as $value) 
		{
    			if(strpos($string,$value)) 
			{
        			return $value;
    			}

		}
		return false;
	}

	// strip percent signs
	$gcode = str_replace('%', "", $gcode);

	// strip comments
	$gcode = preg_replace("/\([^)]+\)/","",$gcode);

	// check for coordinate system
	$coordinate_systems = array( "G54", "G55", "G56", "G57", "G58", "G59.1", "G59.2", "G59.3", "G59");
	$coordinate_system = check_array($coordinate_systems,$gcode);
	if(!$coordinate_system)
	{
		$error = "No Coordinate System Found, Using G54";
		$gcode = "G54\r\n" . $gcode;
	}
	else
	{
		$error = "Found $coordinate_system, Changing to G54 Coordinate System";
		$coordinate_systems_replace = array( "G54", "G54", "G54", "G54", "G54", "G54", "G54", "G54", "G54");	
		$gcode = str_replace($coordinate_systems, $coordinate_systems_replace, $gcode);
	}

	// check for tool changes
	$tools_array = array("T1","T2","T3","T4","T5","T6","T7","T8","T9","T10","T11","T12","T13","T14","T15","T16","T17","T18","T19","T20");
	if(substr_count($gcode, "T") > 1)
	{
		//replace TxM6 with o100 CALL
		$tool_info = "found tools";
		foreach($tools_array as $value)
		{
			if(strpos($gcode,$value))
			{
				$these_tools[substr($value,1,1)] = $value;
			}
		}
		foreach($these_tools as $tool)
		{
			$tool_info .= " $tool";
		}
	}
	elseif(substr_count($gcode, "T") == 1)
	{
		//remove T1M6
		$tool_info = "one tool found";
	}
	else
	{
		//no tool
		$tool_info = "no tools found";
	}
	// preamble should be: G17 G20 G40 G49 G54 G90 G64 P0.001 T0
	
 	$gcode = preg_replace('/[A-Z]/', " $0", $gcode);
	$gcode = str_replace("\r\n ", "\r\n", $gcode);

	echo "%\r\n";
	echo "(PROBOTIX LinuxCNC G-code)\r\n";
	echo "(Filtered by g-code-filter.php version $version)\r\n";
	if($error)
	{
		echo "($error)\r\n";
	}
	echo "($tool_info)\r\n";
	echo $gcode;
	echo "\r\n%";

	//sleep(10);

?>
