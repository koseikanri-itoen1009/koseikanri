/*============================================================================
* �t�@�C���� : XxpoOrderDetailTotalVOImpl
* �T�v����   : ��������ڍ�:���v�Z�o�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-03 1.0  �g�������@   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * ���v�Z�o�r���[�I�u�W�F�N�g�ł��B
 * @author  SCS �g�� ����
 * @version 1.0
 ***************************************************************************
 */
public class XxpoOrderDetailTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoOrderDetailTotalVOImpl()
  {
  }

  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param headerNumber �����ԍ�
   ****************************************************************************/
  public void initQuery(
    String headerNumber    // �����ԍ�
   )
  {

    // ������
    setWhereClauseParams(null);

    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, headerNumber);
  
    // SELECT�����s
    executeQuery();
  }
}