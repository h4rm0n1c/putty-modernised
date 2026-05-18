# Release process

## Tag-driven release

```sh
git checkout main
git pull
git tag -a 0.83-modernised -m "PuTTY Modernised 0.83"
git push origin 0.83-modernised
```

## Manual release

```sh
gh workflow run release.yml -R h4rm0n1c/putty-modernised -f tag=0.83-modernised
gh run watch -R h4rm0n1c/putty-modernised
```

## Release artifacts

- `putty.exe`
- `putty-0.83-modernised-windows-x64.zip`
- `SHA256SUMS.txt`
- `defender-scan.txt`

## Security notes

SHA256 hashes verify artifact integrity. Defender scan logs are one scanner's
result, not proof of safety. Users should download from the GitHub Release and
verify hashes.

## VirusTotal

VirusTotal upload can be added later behind a GitHub secret and explicit
opt-in. It is not included in this pass to keep the base workflow simple
and avoid requiring external service tokens for basic releases.
