/*============================================================================
* �t�@�C���� : XxcsoSpDecisionNotificationVOImpl
* �T�v����   : SP�ꌈ�ʒm��ʏ����l�p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-17 1.0   SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * SP�ꌈ�ʒm��ʂ̏����l��ݒ肷�邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionNotificationVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionNotificationVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param notifyId �ʒmID
   *****************************************************************************
   */
  public void initQuery(
    String notifyId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, notifyId);
    setWhereClauseParam(1, notifyId);

    executeQuery();
  }
}