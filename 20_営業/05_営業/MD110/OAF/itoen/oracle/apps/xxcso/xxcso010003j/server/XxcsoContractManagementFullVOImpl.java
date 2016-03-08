/*============================================================================
* �t�@�C���� : XxcsoContractManagementFullVOImpl
* �T�v����   : �_��Ǘ��e�[�u�����r���[�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
* 2016-01-06 1.1  SCSK�ː��a�K [E_�{�ғ�_13456]���̋@�Ǘ��V�X�e����֑Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �_��Ǘ��e�[�u�����r���[�I�u�W�F�N�g�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractManagementFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractManagementFullVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param contractManagementId �����̔��@�ݒu�_��ID
   *****************************************************************************
   */
  public void initQuery(
    String contractManagementId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, contractManagementId);

    executeQuery();
  }
}