xquery version "3.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "/db/apps/tei-simple/content/util.xql";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd" at "/db/apps/tei-simple/content/odd2odd.xql";

declare namespace expath="http://expath.org/ns/pkg";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

declare variable $local:EXIDE := 
    let $path := collection(repo:get-root())//expath:package[@name = "http://exist-db.org/apps/eXide"]
    return
        if ($path) then
            substring-after(util:collection-name($path), repo:get-root())
        else
            ();
            
declare function local:load-source($href as xs:string, $line as xs:int?) {
    let $link :=
        let $path := string-join(
            (request:get-context-path(), request:get-attribute("$exist:prefix"), $local:EXIDE,
            "index.html?open=" || $href)
            , "/"
        )
        return
            replace($path, "/+", "/")
    return
        <a href="{$link}" target="eXide" class="eXide-open" data-exide-open="{$href}"
            data-exide-line="{$line}">{$href}</a>
};

declare function local:get-line($src, $line as xs:int) {
    let $lines := tokenize($src, "\n")
    return
        replace($lines[$line], "^\s*(.*?)", "$1")
};

let $result :=
    for $source in $config:odd
        for $module in ("web", "print", "latex")
        return
            try {
                for $file in pmu:process-odd(
                    doc(odd:get-compiled($config:odd-root, $config:odd, $config:compiled-odd-root)),
                    $config:output-root,
                    $module,
                    "../" || $config:output,
                    $config:module-config)?("module")
                let $src := util:binary-to-string(util:binary-doc($file))
                let $compiled := util:compile-query($src, ())
                return
                    if ($compiled/error) then
                        <div class="list-group-item-danger">
                            <h5 class="list-group-item-heading">{local:load-source($file, $compiled/error/@line)}:</h5>
                            <p class="list-group-item-text">{ $compiled/error/string() }</p>
                            <pre class="list-group-item-text">{ local:get-line($src, $compiled/error/@line)}</pre>
                        </div>
                    else
                        <div class="list-group-item-success">{$file}</div>
            } catch * {
                <li>Error for output mode {$module}: {$err:description}</li>
            }
return
    <div class="errors">
        <h4>Regenerated XQuery code from ODD files</h4>
        <div class="list-group">
        {
            $result
        }
        </div>
    </div>