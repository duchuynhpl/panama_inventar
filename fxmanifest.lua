fx_version 'adamant'

game 'gta5'

version '1.1.0'
client_scripts {
	'@es_extended/locale.lua',
	'config.lua',
	--'client/variations.lua',
	--'client/clothing.lua',
	'client/client.lua'
}

server_scripts {
	'@es_extended/locale.lua',
	'config.lua',
	'server/server.lua'
}

ui_page 'html/index.html'

files {
	'html/index.html',
	'html/js/svgdata.js',
	'html/js/main.js',
	'html/css/styles.css',
  	-- IMAGES
  	"html/img/bullet.png",
  	-- ICONS
  	"html/img/*.png"
}


-- Nova Leaks : discord.gg/2vubhJDFfh