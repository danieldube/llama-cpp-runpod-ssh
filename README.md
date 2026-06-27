# llama-cpp-runpod-ssh

Derived RunPod image for `ghcr.io/ggml-org/llama.cpp:server-cuda`.

Adds:

- OpenSSH server
- SSH public-key setup from RunPod environment variables
- The same user-facing command syntax as the official `server-cuda` image

## Image

```text
ghcr.io/danieldube/llama-cpp-runpod-ssh:latest