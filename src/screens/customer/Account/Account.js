import React, { Component } from "react";
import { connect } from "react-redux";
import { withRouter, NavLink} from "react-router-dom";
import { Icon } from "react-onsenui";
import "./Account.scss";
import Layout from "../../../components/Layout/Layout";
import { getAccount } from "../../../store/account/thunks";

class Account extends Component {
  componentDidMount() {
    const { getAccount, match } = this.props;
    getAccount(match.params.accountId);
  }

  render() {
    const { account, loading } = this.props;
    return (
      <Layout>
        <div>
          <div className="account-header">
            <NavLink to='/customer/accounts' className="back">
              <Icon size={30} className="fa-angle-left" />
            </NavLink>
            <h2>Account details</h2>
          </div>
          {!loading && account && (
            <React.Fragment>
              <div className="account-detail">
                <div className="title">Nickname:</div>
                <div>{account.nickname}</div>
              </div>
              <div className="account-detail">
                <div className="title">Currency:</div>
                <div>{account.currency}</div>
              </div>
              <div className="account-detail">
                <div className="title">Status:</div>
                <div>{account.status}</div>
              </div>
              <div className="account-detail">
                <div className="title">Type:</div>
                <div>{account.accountType}</div>
              </div>
              <div className="account-detail">
                <div className="title">Owner:</div>
                <div>{account.account[0].name}</div>
              </div>
            </React.Fragment>
          )}
        </div>
      </Layout>
    );
  }
}

const mapStateToProps = state => ({
  account: state.accounts.currentAccount,
  loading: state.accounts.loading
});

const mapDispatchToProps = dispatch => ({
  getAccount: accountId => dispatch(getAccount(accountId))
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(withRouter(Account));