#!/usr/bin/php
<?
	/*
		Call as:
			./writerss.php <versionfile> <build means> <downloadfile> <dsaSignature>
			
		Ex.:
			./writerss.php Output/Stacksmith.app/Contents/Info.plist nightly Output/Stacksmith.tgz 'ND0CFBfeCa1JyW21nbkBwniaOzrN6EQuAb='
	*/
	
	date_default_timezone_set('Europe/Berlin');
	$updatemessage = '';
	$buildsinlist = 0;
	$desirednumdays = date("N");
	ob_start();
	passthru("git log --since=\"$desirednumdays days ago\"");
	$revisions = ob_get_clean();
	
	preg_match_all("/(Date:   |    )(.*)/", $revisions, $matches, PREG_SET_ORDER);
	
	$updatemessage = "";
	$lastdate = "";
	$num = sizeof( $matches );
	for( $x = 0; $x < $num; $x++ )
	{
		if( $matches[$x][1] == "Date:   " )
		{
			$thedate = date( "Y-m-d", strtotime($matches[$x][2]));
			if( $thedate != $lastdate )
			{
				$updatemessage .= "&lt;h3&gt;".htmlentities($thedate)."&lt;/h3&gt;\n";
				$lastdate = $thedate;
			}
		}
		else
			$updatemessage .= htmlentities($matches[$x][2])."&lt;br /&gt;\n";
	}
	
	$infoplist = file_get_contents($argv[1]);
	$matches = array();
	preg_match( '/<key>CFBundleVersion<\\/key>[\r\n]*/', $infoplist, $matches, PREG_OFFSET_CAPTURE );
	$newoffs = $matches[0][1] +strlen($matches[0][0]);
	preg_match( '/<string>(.*)?<\\/string>/', $infoplist, $matches, 0, $newoffs );
	$theversion = $matches[1];
	
	echo "   Version: $theversion\n";
	echo "     Build: $argv[2]\n";
	
	$actualversion = $theversion;
	$tag = str_replace( "__", "_", str_replace( ".", "_", str_replace( " ", "_", str_replace( "(", "_", str_replace( ")", "_", str_replace( "a", "_a", $theversion ) ) ) ) ) );
	$tag = trim ( $tag, " _\t\n\r\0\x0B" );
	$downloadurl="https://github.com/uliwitness/Stacksmith/releases/download/Stacksmith_$tag/".basename($argv[3]);
	$feedstr = "<?xml version=\"1.0\"?>
<rss version=\"2.0\" 
	xmlns:sparkle=\"http://sparkle.andymatuschak.org/rss/1.0/modules/sparkle/\">
  <channel>
    <title>Stacksmith ".$argv[2]." Appcast</title>
    <link>http://stacksmith.org/</link>
    <description>Updates for Stacksmith</description>
    <item>
       <title>Stacksmith $actualversion</title>
       <link>$downloadurl</link>
       <description>".$updatemessage."</description>
       <enclosure url=\"$downloadurl\" length=\"".filesize($argv[3])."\" type=\"application/octet-stream\" sparkle:dsaSignature=\"".$argv[4]."\" />
       <sparkle:version>$actualversion</sparkle:version>
     </item>
  </channel>
</rss>";
	
	$fpath = dirname($argv[0]).'/../Output/'.$argv[2].'_feed.rss';
	$fd = fopen($fpath,"w");
	fwrite($fd,$feedstr);
	fclose($fd);
	
	echo "Written to: $fpath\n";
?>
