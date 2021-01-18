#!/usr/bin/env bash
KUBECONFIG=${KUBECONFIG:-~/.kube/config}
if [[ -z "${K8SVAULT_CONFIG_DIR:-}" ]]; then
  K8SVAULT_CONFIG_DIR="${HOME}/.kube"
fi
if [[ -z "${K8SVAULT_CONFIG:-}" ]]; then
  K8SVAULT_CONFIG="${K8SVAULT_CONFIG_DIR}/k8s-vault.yaml"
fi
COMPREPLY=()
DEPS=( jq oq )
check_dep() {
  if ! which $1 2>&1 >/dev/null; then
    echo >&2 "ERROR: dependency missing - \"${1}\""
    return 1
  fi
}
for dep in ${DEPS[*]}; do
  check_dep $dep
done
if [ ! -r "${K8SVAULT_CONFIG}" ]; then
  echo >&2 "ERROR: unable to read K8SVAULT_CONFIG at \"${K8SVAULT_CONFIG}\""
  return 1
fi
_k8svault_get_contexts()
{
  local contexts
  # if contexts=$(yq r -j ${KUBECONFIG} contexts[*].name); then
  if contexts=$(oq -i yaml '.clusters| .[] | select(.enabled != false) | .name' "${K8SVAULT_CONFIG}"); then
    COMPREPLY+=( $(compgen -W "${contexts[*]}" -- "${_word_last}") )
  fi
}
_k8svault_completion()
{
  local _word_index=$[${COMP_CWORD}-1]
  local _word="${COMP_WORDS[$_word_index]}"
  local _word_last="${COMP_WORDS[-1]}"

  case $_word in
    k8s-vault)
      COMPREPLY+=( $(compgen -W "--debug exec completion" -- "${_word_last}") )
      return
    ;;
    --debug)
      COMPREPLY=( $(compgen -W "exec completion" -- "${_word_last}") )
      return
    ;;
    completion)
      return
    ;;
    exec)
      _k8svault_get_contexts
      return
    ;;
    -*)
      return
    ;;
    \>*)
      return
    ;;
    *)
      COMPREPLY=( -s -- )
      return
    ;;
  esac
}
if [[ $(type -t compopt) = "builtin" ]]; then
  complete -o default -F  _k8svault_completion k8s-vault
else
  complete -o default -o nospace -F  _k8svault_completion k8s-vault
fi
