<?php

// Converts Discord chat json to lua, for importing loot reservation
// syntax : php res.php file.json
// creates resfile.lua
// contents of this file should go in function LootRes:lootres_reserves() in LootRes.lua

$json = json_decode(file_get_contents($argv[1]), 1);

file_put_contents('resfile.lua', 'return {' . PHP_EOL);

foreach ($json['messages'] as $key => $v) {
    $text = explode('-', $v['content']);
    file_put_contents('resfile.lua',
        '["' . trim($text[0]) . '"] = "' . trim($text[1]) . '",' . PHP_EOL,
        FILE_APPEND);
}

file_put_contents('resfile.lua', '}' . PHP_EOL, FILE_APPEND);
