/*============================================================================
* �t�@�C���� : XxcsoElectricVOImpl
* �T�v����   : �d�C��r���[�s�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����         �C�����e
* ---------- ---- -------------- --------------------------------------------
* 2020-08-21 1.0  SCSK���X�ؑ�a   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * �d�C��r���[�I�u�W�F�N�g�N���X
 * @author  SCSK���X�ؑ�a
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoElectricVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoElectricVOImpl()
  {
  }
  
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param spDecisionHeaderId SP�ꌈ�w�b�_�[ID
   *****************************************************************************
   */
  public void initQuery(
    String spDecisionHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, spDecisionHeaderId);

    executeQuery();
  }
}