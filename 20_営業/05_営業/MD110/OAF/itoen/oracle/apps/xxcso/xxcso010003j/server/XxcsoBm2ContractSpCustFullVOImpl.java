/*============================================================================
* �t�@�C���� : XxcsoBm2ContractSpCustFullVOImpl
* �T�v����   : BM2SP�ꌈ�ڋq�e�[�u�����r���[�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * BM2SP�ꌈ�ڋq�e�[�u�����r���[�I�u�W�F�N�g�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoBm2ContractSpCustFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoBm2ContractSpCustFullVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param spDecisionHeaderId SP�ꌈ�w�b�_�[ID
   *****************************************************************************
   */
  public void initQuery(
    Number spDecisionHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, spDecisionHeaderId);

    executeQuery();
  }
}