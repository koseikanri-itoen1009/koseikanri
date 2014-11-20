/*============================================================================
* �t�@�C���� : XxcsoSpDecisionBmFormatVOImpl
* �T�v����   : BM�̍��ڃT�C�Y�ݒ�p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-03-05 1.0   SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * BM���̃T�C�Y��ݒ肷�邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionBmFormatVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionBmFormatVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param vendorName      ���t�於
   * @param vendorNameAlt   ���t�於�i�J�i�j
   * @param state           �s���{��
   * @param city            �s�E��
   * @param address1        �Z���P
   * @param address2        �Z���Q
   *****************************************************************************
   */
  public void initQuery(
    String  vendorName
   ,String  vendorNameAlt
   ,String  state
   ,String  city
   ,String  address1
   ,String  address2
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, vendorName);
    setWhereClauseParam(1, vendorNameAlt);
    setWhereClauseParam(2, state);
    setWhereClauseParam(3, city);
    setWhereClauseParam(4, address1);
    setWhereClauseParam(5, address2);

    executeQuery();
  }
}