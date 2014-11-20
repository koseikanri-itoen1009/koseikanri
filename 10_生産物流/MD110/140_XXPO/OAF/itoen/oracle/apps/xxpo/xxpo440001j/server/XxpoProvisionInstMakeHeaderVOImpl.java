/*============================================================================
* �t�@�C���� : XxpoProvisionInstMakeHeaderVOImpl
* �T�v����   : �x���w���쐬�w�b�_�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-10 1.0  ��r���     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �x���w���쐬�w�b�_�r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionInstMakeHeaderVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionInstMakeHeaderVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param reqNo - �˗�No
   ****************************************************************************/
  public void initQuery(String reqNo)
  {
    // ������
    setWhereClauseParams(null);
    setWhereClauseParam(0, reqNo);
    // �������s
    executeQuery();
  }
}