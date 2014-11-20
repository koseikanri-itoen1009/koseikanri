/*============================================================================
* �t�@�C���� : XxinvLineVOImpl
* �T�v����   : �o�ɁE���Ƀ��b�g���׉��(�ړ��w������)�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-11 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �o�ɁE���Ƀ��b�g���׉��(�ړ��w������)�r���[�I�u�W�F�N�g�ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxinvLineVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvLineVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param movLineId     - �ړ�����ID
   * @param productFlg    - ���i���ʋ敪
   ****************************************************************************/
  public void initQuery(
    String      movLineId,
    String      productFlg
    )
  {
    // ������
    setWhereClauseParams(null);
          
    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, productFlg);
    setWhereClauseParam(1, productFlg);
    setWhereClauseParam(2, productFlg);
    setWhereClauseParam(3, movLineId);
  
    // SELECT�����s
    executeQuery();
  }
}