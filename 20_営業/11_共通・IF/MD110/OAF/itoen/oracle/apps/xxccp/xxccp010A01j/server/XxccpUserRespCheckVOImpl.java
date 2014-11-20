/*============================================================================
* �t�@�C���� : XxccpUserRespCheckVOImpl
* �T�v����   : ���[�U�[�E�E�Ӄ`�F�b�N�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-08-10 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp010A01j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * ���O�C�����[�U�[�̐E�ӂ��`�F�b�N���邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxccpUserRespCheckVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpUserRespCheckVOImpl()
  {
  }


  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param userName ���O�C�����[�U�[��
   *****************************************************************************
   */
  public void initQuery(
    String userName
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, userName);
    setWhereClauseParam(1, userName);

    executeQuery();
  }
}