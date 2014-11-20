/*============================================================================
* �t�@�C���� : XxpoPoConfirmVOImpl
* �T�v����   : �����m�F���:�����r���[�I�u�W�F�N�g
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-03 1.0  �ɓ��ЂƂ�   �V�K�쐬
* 2009-02-24 1.1  ��r�@���   �{�ԏ�Q#5�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.server;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import java.util.ArrayList;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Date;
/***************************************************************************
 * �����r���[�I�u�W�F�N�g�ł��B
 * @author  SCS �ɓ��ЂƂ�
 * @version 1.1
 ***************************************************************************
 */
public class XxpoPoConfirmVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoPoConfirmVOImpl()
  {
  }

  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchParams         // �����L�[�p�����[�^
   ****************************************************************************/
  public void initQuery(HashMap searchParams)
  {

    StringBuffer whereClause = new StringBuffer(1000);  // WHERE��쐬�p�I�u�W�F�N�g
    ArrayList parameters = new ArrayList();             // �o�C���h�ϐ��ݒ�l
    int bindCount = 0;                                  // �o�C���h�ϐ��J�E���g

    // ������
    setWhereClauseParams(null);

    // ���������擾
    String headerNumber        = (String)searchParams.get("headerNumber");        // ����No.
    Object vendorId            = searchParams.get("vendorId");                    // �����ID     
    Object mediationId         = searchParams.get("mediationId");                 // ������ID
    String status              = (String)searchParams.get("status");              // �X�e�[�^�X
    String location            = (String)searchParams.get("location");            // �[�i��R�[�h
    String department          = (String)searchParams.get("department");          // ���������R�[�h
    String approved            = (String)searchParams.get("approved");            // �����v
    String purchase            = (String)searchParams.get("purchase");            // �����敪
    String orderApproved       = (String)searchParams.get("orderApproved");       // ��������
    String cancelSearch        = (String)searchParams.get("cancelSearch");        // �������
    String purchaseApproved    = (String)searchParams.get("purchaseApproved");    // �d������
    String peopleCode          = (String)searchParams.get("peopleCode");          // �]�ƈ��敪
    Date   deliveryDateFrom    = (Date)searchParams.get("deliveryDateFrom");      // �[����FROM
    Date   deliveryDateTo      = (Date)searchParams.get("deliveryDateTo");        // �[����TO
    Object outSideUsrVendorId  = null;                                            // �������ID
    Object outSideUsrFactoryCode = null;                                          // ���H��R�[�h

    // *************************** //
    // *        �����쐬         * //
    // *************************** //
    
    // �]�ƈ��敪��2:�O�����[�U�̏ꍇ
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {
      // �������ID�E���H��R�[�h���擾
      outSideUsrVendorId  = searchParams.get("outSideUsrVendorId");
      outSideUsrFactoryCode = searchParams.get("outSideUsrFactoryCode");

      // ���H��ID�ɐݒ肪����ꍇ�A���H��R�[�h��ݒ�
      if (XxcmnUtility.isBlankOrNull(outSideUsrFactoryCode) == false)
      {
        // �R�t���������ׂɁA���H��R�[�h�łȂ��������ׂ����݂��Ȃ����́B
        whereClause.append(" ((mediation_id = :" + bindCount + ")");
        whereClause.append(" OR ((vendor_id = :" + (++bindCount) +")");
        whereClause.append("     AND (NOT EXISTS ( " );
        whereClause.append("           SELECT 1 " );
        whereClause.append("           FROM   po_lines_all pla " );
        whereClause.append("           WHERE  pla.po_header_id = header_id " );
        whereClause.append("           AND    pla.attribute2  <> :" + (++bindCount) + ")))) " );
        
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;      
        parameters.add(outSideUsrVendorId); 
        parameters.add(outSideUsrVendorId); 
      
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(outSideUsrFactoryCode);      

      // ���H��ID�ɐݒ肪�Ȃ��ꍇ�A���H��R�[�h��ݒ肵�Ȃ�
      } else
      {
        whereClause.append(" ((mediation_id = :" + bindCount + ")");
        whereClause.append(" OR (vendor_id = :" + (++bindCount) +")) ");

        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;      
        parameters.add(outSideUsrVendorId); 
        parameters.add(outSideUsrVendorId); 
      }

    }
    
    // ����No.�����͂���Ă����ꍇ
    if (XxcmnUtility.isBlankOrNull(headerNumber) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND header_number = :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" header_number = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;     
      //�����l���Z�b�g
      parameters.add(headerNumber);      
// 2009-02-24 D.Nihei Mod Start �{�ԏ�Q#5�Ή�
//    }
    } else
    {
// 2009-02-24 D.Nihei Mod End
        
      // ����悪���͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(vendorId) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND vendor_id = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" vendor_id = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(vendorId);      
      }

      // �����҂����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(mediationId) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND mediation_id = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" mediation_id = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(mediationId);      
      }

      // �[����From�����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(deliveryDateFrom) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND delivery_date >= :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" delivery_date >= :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(deliveryDateFrom);
      }

      // �[����To�����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(deliveryDateTo) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND delivery_date <= :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" delivery_date <= :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(deliveryDateTo);      
      }

      // �X�e�[�^�X�����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(status) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND status_code = :" + bindCount);
        // �����ǉ�1���ڂ̏ꍇ
        }else
        {
          whereClause.append(" status_code = :" + bindCount); 
        }
      
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(status);  
      }

      // ���������ON�ɂȂ��Ă��Ȃ��ꍇ(����͌����s��)
      if (XxcmnUtility.isBlankOrNull(cancelSearch) == true)
      {
        // �X�e�[�^�X�����͂���Ă��Ȃ��A���́A���(99)�Ŗ����ꍇ
        if ((XxcmnUtility.isBlankOrNull(status) == true) 
          || !(XxpoConstants.STATUS_CANCEL.equals(status)))
        {
          // �����ǉ�1���ڈȍ~�̏ꍇ
          if (whereClause.length() != 0)
          {
            whereClause.append(" AND status_code != '99' ");
          // �����ǉ�1���ڂ̏ꍇ
          }else
          {
          whereClause.append(" status_code != '99' "); 
          }
        }
      }

      // �[���悪���͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(location) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND location_code = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" location_code = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(location);      
      }

      // �������������͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(department) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND department_code = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" department_code = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(department);      
      }

      // �����v�����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(approved) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND approved_flag = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" approved_flag = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;
        //�����l���Z�b�g    
        parameters.add(approved);      
      }

      // �����敪�����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(purchase) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND dropship_code = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" dropship_code = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;

        //�����l���Z�b�g
        parameters.add(purchase);      
      }

      // �������������͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(orderApproved) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND order_approved_flag = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" order_approved_flag = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;
      
        //�����l���Z�b�g
        parameters.add(orderApproved);      
      }

      // �d�����������͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(purchaseApproved) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND purchase_approved_flag = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" purchase_approved_flag = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;
      
        //�����l���Z�b�g
        parameters.add(purchaseApproved);      
      }
// 2009-02-24 D.Nihei Add Start �{�ԏ�Q#5�Ή�
    }
// 2009-02-24 D.Nihei Add End

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
    
    executeQuery();
  }
}