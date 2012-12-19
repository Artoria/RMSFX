module CocoSimple::External
        def self.gccTree(file)
                x = `gcc -Wp,-fsyntax-only,-fdump-tree-all #{file}`
                file = File.read(file+".001t.tu");
                file
        end
end
