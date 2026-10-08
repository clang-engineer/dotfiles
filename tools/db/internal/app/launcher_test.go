package app

import "testing"

func TestCatalogSelectionIsIsolated(t *testing.T) {
	t.Parallel()
	first := map[string]connection{"first": {Project: "one", Tools: []string{"harlequin"}}}
	second := map[string]connection{"second": {Project: "two", Tools: []string{"rainfrog"}}}
	if got := availableConnections(first, "harlequin", "one"); len(got) != 1 {
		t.Fatal("missing first catalog connection")
	}
	if got := availableConnections(second, "harlequin", ""); len(got) != 0 {
		t.Fatal("catalog state leaked")
	}
	if got := availableConnections(first, "harlequin", "two"); len(got) != 0 {
		t.Fatal("project filter ignored")
	}
	if err := previewConnection(second, "rainfrog", "first"); err == nil {
		t.Fatal("preview used a different catalog")
	}
}

func TestDefaultUsesProvidedCatalog(t *testing.T) {
	setupCatalog(t)
	if _, err := saveDefault("harlequin", "local-db"); err != nil {
		t.Fatal(err)
	}
	good := map[string]connection{"local-db": {Tools: []string{"harlequin"}}}
	tool, id, ok, err := loadDefault(good)
	if err != nil || !ok || tool != "harlequin" || id != "local-db" {
		t.Fatalf("unexpected default: %s %s %v %v", tool, id, ok, err)
	}
	if _, _, _, err := loadDefault(nil); err == nil {
		t.Fatal("missing connection accepted")
	}
	wrongTool := map[string]connection{"local-db": {Tools: []string{"rainfrog"}}}
	if _, _, _, err := loadDefault(wrongTool); err == nil {
		t.Fatal("unsupported default tool accepted")
	}
}

func TestLaunchRejectsInvalidSelection(t *testing.T) {
	t.Parallel()
	catalog := map[string]connection{"local": {Tools: []string{"harlequin", "unknown"}}}
	for _, pair := range [][2]string{{"harlequin", "missing"}, {"rainfrog", "local"}, {"unknown", "local"}} {
		code, err := launchConnection(catalog, "", pair[0], pair[1])
		if code != 1 || err == nil {
			t.Fatalf("invalid selection accepted: %v", pair)
		}
	}
}
