/*============================================================================
* �t�@�C���� : XxpoSupplierResultsTotalVOImpl
* �T�v����   : �d���o�׎���:���v�Z�o�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-18 1.0  �g�������@   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * ���v�Z�o�r���[�I�u�W�F�N�g�ł��B
 * @author  SCS �g�� ����
 * @version 1.0
 ***************************************************************************
 */
public class XxpoSupplierResultsTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoSupplierResultsTotalVOImpl()
  {
  }

  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchId �����p�����[�^ID
   ****************************************************************************/
  public void initQuery(
    String searchId         // �����p�����[�^ID
   )
  {
    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, searchId);
  
    // SELECT�����s
    executeQuery();
  }
}