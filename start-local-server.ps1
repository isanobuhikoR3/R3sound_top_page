param(
  [ValidateRange(1024, 65535)]
  [int]$Port = 8000
)

$siteRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()

$mimeTypes = @{
  '.css' = 'text/css; charset=utf-8'
  '.csv' = 'text/csv; charset=utf-8'
  '.html' = 'text/html; charset=utf-8'
  '.js' = 'text/javascript; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.mp3' = 'audio/mpeg'
  '.png' = 'image/png'
}

Write-Host "Server started: http://localhost:$Port"
Write-Host 'Press Ctrl + C to stop the server.'

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $relativePath = [uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($relativePath)) { $relativePath = 'index.html' }
    $requestedPath = [System.IO.Path]::GetFullPath((Join-Path $siteRoot $relativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)))

    if (-not $requestedPath.StartsWith($siteRoot, [System.StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $requestedPath -PathType Leaf)) {
      $context.Response.StatusCode = 404
      $context.Response.Close()
      continue
    }

    $extension = [System.IO.Path]::GetExtension($requestedPath).ToLowerInvariant()
    $context.Response.ContentType = if ($mimeTypes.ContainsKey($extension)) { $mimeTypes[$extension] } else { 'application/octet-stream' }
    $bytes = [System.IO.File]::ReadAllBytes($requestedPath)
    $context.Response.ContentLength64 = $bytes.Length
    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $context.Response.Close()
  }
}
finally {
  $listener.Stop()
  $listener.Close()
}
