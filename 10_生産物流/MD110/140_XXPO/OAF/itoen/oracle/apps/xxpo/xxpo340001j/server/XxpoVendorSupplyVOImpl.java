/*============================================================================
* �t�@�C���� : XxpoVendorSupplyVOImpl
* �T�v����   : �O���o������:�����r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-10 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo340001j.server;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

import java.util.ArrayList;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �O���o������:�����r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �ɓ� �ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxpoVendorSupplyVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoVendorSupplyVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchParams         - �����L�[�p�����[�^
   * @param manufacturedDateFrom - ���Y��FROM
   * @param manufacturedDateTo   - ���Y��TO
   * @param productedDateFrom    - ������FROM
   * @param productedDateTo      - ������TO
   ****************************************************************************/
  public void initQuery(
    HashMap        searchParams,         // �����L�[�p�����[�^
    java.sql.Date  manufacturedDateFrom, // ���Y��FROM
    java.sql.Date  manufacturedDateTo,   // ���Y��TO
    java.sql.Date  productedDateFrom,    // ������FROM
    java.sql.Date  productedDateTo       // ������TO
   )
  {
    StringBuffer whereClause = new StringBuffer(1000);  // WHERE��쐬�p�I�u�W�F�N�g
    ArrayList parameters = new ArrayList();             // �o�C���h�ϐ��ݒ�l
    int bindCount = 0;                                  // �o�C���h�ϐ��J�E���g

    // ������
    setWhereClauseParams(null);

    // *************************** //
    // *        �����쐬         * //
    // *************************** //
    // �����L�[�擾
    String lotNumber   = (String)searchParams.get("lotNumber");
    String vendorCode  = (String)searchParams.get("vendorCode");
    String factoryCode = (String)searchParams.get("factoryCode");
    String itemCode    = (String)searchParams.get("itemCode");
    String koyuCode    = (String)searchParams.get("koyuCode");
    String corrected   = (String)searchParams.get("corrected");

    // ���b�g�ԍ��ɓ��͂�����ꍇ�A�����ɒǉ�
    if (XxcmnUtility.isBlankOrNull(lotNumber) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND lot_number = :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" lot_number = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;     
      //�����l���Z�b�g
      parameters.add(lotNumber);
    }

    // ���Y��FROM�ɓ��͂�����ꍇ�A�����ɒǉ�
    if (XxcmnUtility.isBlankOrNull(manufacturedDateFrom) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND manufactured_date >= :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" manufactured_date >= :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(manufacturedDateFrom);
    }

    // ���Y��TO�ɓ��͂�����ꍇ�A�����ɒǉ�
    if (XxcmnUtility.isBlankOrNull(manufacturedDateTo) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND manufactured_date <= :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" manufactured_date <= :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;   
      //�����l���Z�b�g
      parameters.add(manufacturedDateTo);
    }

    // �����ɓ��͂�����ꍇ�A�����ɒǉ�
    if (XxcmnUtility.isBlankOrNull(vendorCode) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND vendor_code = :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" vendor_code = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(vendorCode);
    }

    // �H��ɓ��͂�����ꍇ�A�����ɒǉ�
    if (XxcmnUtility.isBlankOrNull(factoryCode) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND factory_code = :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" factory_code = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;   
      //�����l���Z�b�g
      parameters.add(factoryCode);
    }

    // �i�ڂɓ��͂�����ꍇ�A�����ɒǉ�
    if (XxcmnUtility.isBlankOrNull(itemCode) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND item_code = :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" item_code = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(itemCode);
    }

    // �ŗL�L���ɓ��͂�����ꍇ�A�����ɒǉ�
    if (XxcmnUtility.isBlankOrNull(koyuCode) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND koyu_code = :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" koyu_code = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(koyuCode);
    }

    // ������FROM�ɓ��͂�����ꍇ�A�����ɒǉ�
    if (XxcmnUtility.isBlankOrNull(productedDateFrom) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND producted_date >= :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" producted_date >= :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(productedDateFrom);
    }

    // ������TO�ɓ��͂�����ꍇ�A�����ɒǉ�
    if (XxcmnUtility.isBlankOrNull(productedDateTo) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND producted_date <= :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" producted_date <= :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(productedDateTo);
    }

    // �����L�ɓ��͂�����ꍇ�A�u�������ʂɓ��͂̂�����́v
    if (XxcmnUtility.isBlankOrNull(corrected) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND corrected_quantity IS NOT NULL ");
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" corrected_quantity IS NOT NULL ");
      }
    
    // �����L�ɓ��͂��Ȃ��ꍇ�A�u�������ʂɓ��͂̂Ȃ����́v
    } else
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND corrected_quantity IS NULL ");
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" corrected_quantity IS NULL ");
      }
    }

    // ����������VO�ɃZ�b�g
    setWhereClause(whereClause.toString());
      
    // �o�C���h�l���ݒ肳��Ă����ꍇ
    if (bindCount > 0)
    {
      // �����l�z����擾
      Object[] params = new Object[bindCount];
      params = parameters.toArray();  
      // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
      setWhereClauseParams(params);
    }

    // *************************** //
    // *        �������s         * //
    // *************************** //  
    executeQuery();
  }
}