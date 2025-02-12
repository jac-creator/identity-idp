require 'rails_helper'

describe 'idv/session_errors/warning.html.erb' do
  let(:sp_name) { 'Example SP' }
  let(:remaining_attempts) { 5 }

  before do
    decorated_session = instance_double(ServiceProviderSessionDecorator, sp_name: sp_name)
    allow(view).to receive(:decorated_session).and_return(decorated_session)

    assign(:remaining_attempts, remaining_attempts)

    render
  end

  it 'shows a primary action' do
    expect(rendered).to have_link(t('idv.failure.button.warning'), href: idv_doc_auth_path)
  end

  it 'shows remaining attempts' do
    expect(rendered).to have_text(t('idv.failure.attempts', count: remaining_attempts))
  end

  it 'renders a list of troubleshooting options' do
    expect(rendered).to have_link(
      t('idv.troubleshooting.options.get_help_at_sp', sp_name: sp_name),
      href: return_to_sp_failure_to_proof_path(step: 'verify_info', location: 'warning'),
    )
  end
end
