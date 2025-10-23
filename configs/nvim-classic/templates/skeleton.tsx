import React from 'react';
import { connect } from 'react-redux';
import { IRootState } from "app/shared/reducers";

export interface ISkeleton extends StateProps, DispatchProps {

}

export const Skeleton = (props: ISkeleton) => {

  return (<>test</>);

};


const mapStateToProps = ({skeleton}: IRootState) => ({});

const mapDispatchToProps = {};

type StateProps = ReturnType<typeof mapStateToProps>;
type DispatchProps = typeof mapDispatchToProps;

export default connect(mapStateToProps, mapDispatchToProps)(Skeleton);
