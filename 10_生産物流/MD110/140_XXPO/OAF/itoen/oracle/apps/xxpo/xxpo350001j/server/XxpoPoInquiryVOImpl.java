/*============================================================================
* �t�@�C���� : XxpoPoInquiryVOImpl
* �T�v����   : �����E����Ɖ��ʃr���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �����E����Ɖ��ʃr���[�I�u�W�F�N�g�ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxpoPoInquiryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoPoInquiryVOImpl()
  {
  }

  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchHeaderId         - �����p�����[�^
   ****************************************************************************/
  public void initQuery(String searchHeaderId)
  {
    // ������
    setWhereClauseParams(null);
          
    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, searchHeaderId);
  
    // SELECT�����s
    executeQuery();
  }
}