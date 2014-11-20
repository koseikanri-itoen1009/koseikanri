/*============================================================================
* �t�@�C���� : XxpoProvisionInstMakeLineVOImpl
* �T�v����   : �x���w���쐬�R�s�[���׃r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-06-09 1.0  ��r���     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �x���w���쐬�R�s�[���׃r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvCopyLineVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvCopyLineVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param exeType       - �N���^�C�v
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   ****************************************************************************/
  public void initQuery(String exeType, Number orderHeaderId)
  {
    // ������
    setWhereClauseParams(null);
    int i = 0;
    setWhereClauseParam(i++, exeType);
    setWhereClauseParam(i++, orderHeaderId);
    // �������s
    executeQuery();
  }
}