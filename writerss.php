#!/usr/bin/php
<?
	/*
		Call as:
			./writerss.php <versionfile> <build means> <downloadfile>
			
		Ex.:
			./writerss.php build/Stacksmith.app/Contents/Info.plist nightly build/Stacksmith.tgz
	*/

	$infoplist = file_get_contents(dirname($argv[0]).'/'.$argv[1]);
	$matches = array();
	preg_match( '/<key>CFBundleVersion<\\/key>[\r\n]*/', $infoplist, $matches, PREG_OFFSET_CAPTURE );
	$newoffs = $matches[0][1] +strlen($matches[0][0]);
	preg_match( '/<string>(.*)?<\\/string>/', $infoplist, $matches, 0, $newoffs );
	$theversion = $matches[1];
	
	$actualversion = $theversion;
	$feedstr = "<?xml version=\"1.0\"?>
<rss version=\"2.0\" 
	xmlns:sparkle=\"http://sparkle.andymatuschak.org/rss/1.0/modules/sparkle/\">
  <channel>
    <title>Stacksmith ".$argv[2]." Appcast</title>
    <link>http://stacksmith.org/</link>
    <description>Updates for Stacksmith</description>
    <item>
       <title>Stacksmith $actualversion</title>
       <link>http://stacksmith.org/nightlies/".basename($argv[3])."</link>
       <description>Build means: ".$argv[2]."</description>
       <enclosure url=\"http://stacksmith.org/nightlies/".basename($argv[3])."\" length=\"".filesize(dirname($argv[0]).'/'.$argv[3])."\" type=\"application/octet-stream\" />
       <sparkle:version>$actualversion</sparkle:version>
     </item>
  </channel>
</rss>";
	
	$fpath = dirname($argv[0]).'/build/'.$argv[2].'_feed.rss';
	$fd = fopen($fpath,"w");
	fwrite($fd,$feedstr);
	fclose($fd);
?>