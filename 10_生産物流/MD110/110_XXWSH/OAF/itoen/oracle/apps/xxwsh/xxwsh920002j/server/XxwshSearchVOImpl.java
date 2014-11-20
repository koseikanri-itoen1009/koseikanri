/*============================================================================
* �t�@�C���� : XxwshSearchVOImpl
* �T�v����   : ���������\�����[�W�����r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-17 1.0  �k�������v     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import oracle.jbo.domain.Date;
/***************************************************************************
 * ���������\�����[�W�����r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �k���� ���v
 * @version 1.0
 ***************************************************************************
 */
public class XxwshSearchVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshSearchVOImpl()
  {
  }
  
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param itemCode                - �i�ڃR�[�h
   * @param activeDate              - �K�p��
   * @param callPictureKbn          - �ďo��ʋ敪
   * @param instructQty             - �w������(�i�ڒP��)
   * @param sumReservedQuantityItem - ��������(�i�ڒP��)
   ****************************************************************************/
  public void initQuery(
    String itemCode,
    Date activeDate,
    String callPictureKbn,
    String instructQty,
    String sumReservedQuantityItem) 
  {
    if (!XxcmnUtility.isBlankOrNull(itemCode))
    {
      // WHERE���������
      setWhereClauseParams(null); // Always reset
      // �o�C���h�ϐ��ɒl���Z�b�g
      setWhereClauseParam(0,  callPictureKbn);          // �ďo��ʋ敪
      setWhereClauseParam(1,  callPictureKbn);          // �ďo��ʋ敪
      setWhereClauseParam(2,  callPictureKbn);          // �ďo��ʋ敪
      setWhereClauseParam(3,  instructQty);             // �w������(�i�ڒP��)
      setWhereClauseParam(4,  callPictureKbn);          // �ďo��ʋ敪
      setWhereClauseParam(5,  instructQty);             // �w������(�i�ڒP��)
      setWhereClauseParam(6,  instructQty);             // �w������(�i�ڒP��)
      setWhereClauseParam(7,  callPictureKbn);          // �ďo��ʋ敪
      setWhereClauseParam(8,  sumReservedQuantityItem); // ��������(�i�ڒP��)
      setWhereClauseParam(9,  callPictureKbn);          // �ďo��ʋ敪
      setWhereClauseParam(10, sumReservedQuantityItem); // ��������(�i�ڒP��)
      setWhereClauseParam(11, sumReservedQuantityItem); // ��������(�i�ڒP��)
      setWhereClauseParam(12, callPictureKbn);          // �ďo��ʋ敪
      setWhereClauseParam(13, callPictureKbn);          // �ďo��ʋ敪
      setWhereClauseParam(14, itemCode);                // �i�ڃR�[�h
      setWhereClauseParam(15, activeDate);              // �K�p��
      // �������s
      executeQuery();
    }
  }
}