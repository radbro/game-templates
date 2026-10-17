import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from patch_godot_web import ORIGINAL, patch_text

# Exact function body from the pinned official Godot web export.
FUNCTION = ORIGINAL + 'try{const cb=GodotRuntime.get_func(p_update_cb);navigator.serviceWorker.getRegistration().then(GodotPWA.updateState.bind(null,cb))}catch(e){GodotRuntime.error("Failed to assign PWA callback",e)}}}'


class GodotWebTests(unittest.TestCase):
    def test_unknown_export_is_rejected(self):
        with self.assertRaises(ValueError):
            patch_text('different engine output')
        with self.assertRaises(ValueError):
            patch_text(FUNCTION + FUNCTION)

    def test_opaque_sandbox_does_not_query_service_worker(self):
        source = '''global.window={origin:'null'};
        Object.defineProperty(globalThis,'navigator',{configurable:true,value:{get serviceWorker(){throw Error('opaque origin')}}});
        global.GodotRuntime={get_func(){return()=>{}},error(){throw Error('unexpected API query')}};
        ''' + patch_text(FUNCTION) + ';_godot_js_pwa_cb(0);'
        subprocess.run(['node', '-e', source], check=True)

    def test_normal_origin_keeps_the_engine_callback(self):
        source = '''let called=false;
        global.window={origin:'https://example.test'};
        Object.defineProperty(globalThis,'navigator',{configurable:true,value:{serviceWorker:{getRegistration(){called=true;return Promise.resolve(null)}}}});
        global.GodotRuntime={get_func(){return()=>{}},error(){throw Error('unexpected error')}};
        global.GodotPWA={updateState(){}};
        ''' + patch_text(FUNCTION) + ';_godot_js_pwa_cb(0);if(!called)throw Error("callback skipped");'
        subprocess.run(['node', '-e', source], check=True)
