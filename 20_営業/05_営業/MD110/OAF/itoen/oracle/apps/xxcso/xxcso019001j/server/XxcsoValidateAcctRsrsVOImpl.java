/*============================================================================
* �t�@�C���� : XxcsoValidateAcctRsrsVOImpl
* �T�v����   : �K��E����v���ʁ@�o���f�[�V�����`�F�b�N�r���[�N���X
*             �ڋq�S���c�ƈ�(�ŐV)VIEW�̑��݃`�F�b�N
*             �ڋq�}�X�^VIEW�̖K��Ώۋ敪�A�p�[�e�BID�擾
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-09 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �K��E����v���ʁ@�o���f�[�V�����`�F�b�N�r���[�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoValidateAcctRsrsVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoValidateAcctRsrsVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param accountNumber   �ڋq�R�[�h
   * @param employeeNumber  �]�ƈ��ԍ�
   * @param planYearMonth   �v��N��
   *****************************************************************************
   */
  public void initQuery(
    String accountNumber
   ,String employeeNumber
   ,String planYearMonth
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    
    setWhereClauseParam(index++, employeeNumber);
    setWhereClauseParam(index++, accountNumber);
    setWhereClauseParam(index++, planYearMonth);
    setWhereClauseParam(index++, planYearMonth);
    setWhereClauseParam(index++, planYearMonth);

    executeQuery();
  }
  
}