

specialStateTransitionMethod(dfa) ::= <<
def special_state_transition_for_dfa<dfa.decisionNumber>(s, input)
  case s
  <dfa.specialStateSTs:{state|when <i0>
  <state>}; separator="\n">
  end
<if(backtracking)>
  @state.backtracking > 0 and raise ANTLR3::Error::BacktrackingFailed<\n>
<endif>
  nva = ANTLR3::Error::NoViableAlternative.new(@dfa<dfa.decisionNumber>.description, <dfa.decisionNumber>, s, input)
  @dfa<dfa.decisionNumber>.error(nva)
  raise nva
end
>>