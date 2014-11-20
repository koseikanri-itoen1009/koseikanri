/*============================================================================
* �t�@�C���� : XxcsoSalesNotifyUserSumVOImpl
* �T�v����   : �ʒm�҃��X�g�����擾�p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-28 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �ʒm�҃��X�g�������擾���邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesNotifyUserSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesNotifyUserSumVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param leadId ���kID
   *****************************************************************************
   */
  public void initQuery(
    Number leadId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, leadId);

    executeQuery();
  }
}